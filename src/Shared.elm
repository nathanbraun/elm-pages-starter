port module Shared exposing
    ( Data
    , Model
    , Msg(..)
    , SharedMsg(..)
    , Test
    , TestId(..)
    , Version(..)
    , template
    )

import Analytics
import Browser.Navigation
import Css.Global exposing (global)
import DataSource
import Html exposing (Html)
import Html.Styled exposing (a, div, text, toUnstyled)
import Html.Styled.Attributes as Attr exposing (css)
import Json.Decode as Decode exposing (Decoder, field, string)
import Json.Encode as Encode
import Pages.Flags exposing (Flags(..))
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Random exposing (Generator)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg


type alias Data =
    ()


type SharedMsg
    = RandomVersions (List Test) (List Version)


type alias Model =
    { showMobileMenu : Bool
    , tests : List Test
    }


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init navigationKey flags maybePagePath =
    let
        trackPage =
            case maybePagePath of
                Nothing ->
                    Cmd.none

                Just pagePath ->
                    pagePath.path.path |> Path.toAbsolute |> Analytics.trackPageNavigation

        loadTests =
            case flags of
                BrowserFlags value ->
                    case Decode.decodeValue testsDecoder value of
                        Ok stored ->
                            Random.generate (RandomVersions stored >> SharedMsg)
                                (randomVersions
                                    (List.length tests)
                                )

                        Err error ->
                            Random.generate (RandomVersions [] >> SharedMsg)
                                (randomVersions
                                    (List.length tests)
                                )

                PreRenderFlags ->
                    Cmd.none
    in
    ( { showMobileMenu = False, tests = [] }
    , Cmd.batch
        [ trackPage
        , loadTests

        -- TODO: get from localhost/write here
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange newPage ->
            ( { model | showMobileMenu = False }
            , newPage.path |> Path.toAbsolute |> Analytics.trackPageNavigation
            )

        SharedMsg (RandomVersions stored versions) ->
            let
                randomTests =
                    List.map2 Test tests versions

                newTests =
                    List.filter
                        (\x ->
                            List.member x.testId
                                (stored
                                    |> List.map
                                        .testId
                                )
                                |> not
                        )
                        randomTests

                seenTests =
                    List.filter
                        (\x ->
                            List.member x.testId tests
                        )
                        stored

                updatedTests =
                    seenTests ++ newTests
            in
            ( { model | tests = updatedTests }, saveTests updatedTests )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view sharedData page model toMsg pageView =
    { body =
        toUnstyled <|
            div []
                [ global Tw.globalStyles
                , div
                    [ css
                        [ Tw.bg_gray_100
                        , Tw.font_sans
                        , Tw.text_lg
                        , Tw.flex
                        , Tw.justify_center
                        , Tw.h_full
                        , Tw.min_h_screen
                        , Tw.text_gray_700
                        ]
                    ]
                    [ div
                        [ css [ Bp.md [ Tw.mt_8 ], Tw.max_w_3xl, Tw.flex_col ] ]
                        (header page.path :: pageView.body)
                    ]
                ]
    , title = pageView.title
    }


randomVersion : Generator Version
randomVersion =
    Random.map
        (\x ->
            if x == 1 then
                A

            else
                B
        )
        (Random.int 1 2)


type Version
    = A
    | B


type TestId
    = TestId String


tests : List TestId
tests =
    [ TestId "example-test"
    ]


type alias Test =
    { testId : TestId
    , version : Version
    }


randomVersions : Int -> Generator (List Version)
randomVersions size =
    Random.list size randomVersion


testsEncoder : List Test -> Decode.Value
testsEncoder ts =
    Encode.list testEncoder ts


testEncoder : Test -> Decode.Value
testEncoder { testId, version } =
    Encode.object
        [ ( "testId", Encode.string (testId |> (\(TestId x) -> x)) )
        , ( "version", Encode.string (versionToString version) )
        ]


versionToString : Version -> String
versionToString version =
    case version of
        A ->
            "A"

        B ->
            "B"


versionDecoder : Decoder Version
versionDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case str of
                    "A" ->
                        Decode.succeed A

                    "B" ->
                        Decode.succeed B

                    _ ->
                        Decode.fail "Unknown version."
            )


testsDecoder : Decoder (List Test)
testsDecoder =
    Decode.list testDecoder


testDecoder : Decoder Test
testDecoder =
    Decode.map2 Test
        (field "testId" string |> Decode.map TestId)
        (field "version" versionDecoder)


saveTests : List Test -> Cmd a
saveTests =
    storeTests << testsEncoder


port storeTests : Decode.Value -> Cmd a


header : Path -> Html.Styled.Html msg
header path =
    case Path.toRelative path of
        "" ->
            div [] []

        "posts" ->
            div [ css [ Bp.md [ Tw.ml_0 ], Tw.ml_3, Tw.mt_4, Tw.mb_6 ] ]
                [ a
                    [ Attr.href "/"
                    , css
                        [ Tw.w_auto
                        , Tw.text_blue_600
                        ]
                    ]
                    [ text
                        "← Home"
                    ]
                , text " | "
                , a
                    [ Attr.href "/feed.xml"
                    , css
                        [ Tw.w_auto
                        , Tw.text_blue_600
                        ]
                    ]
                    [ text
                        "RSS"
                    ]
                ]

        _ ->
            div [ css [ Bp.md [ Tw.ml_0 ], Tw.ml_3, Tw.mt_4, Tw.mb_6 ] ]
                [ a
                    [ Attr.href "/"
                    , css
                        [ Tw.mt_10
                        , Tw.w_auto
                        , Tw.text_blue_600
                        ]
                    ]
                    [ text
                        "← Home"
                    ]
                , text " | "
                , a
                    [ Attr.href "/posts"
                    , css
                        [ Tw.mt_10
                        , Tw.w_auto
                        , Tw.text_blue_600
                        ]
                    ]
                    [ text
                        "Posts"
                    ]
                ]
