module Page.SPLAT__ exposing (Data, Model, Msg, page)

import Browser.Navigation
import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob exposing (Glob)
import Date exposing (Date)
import Head
import Head.Seo as Seo
import Html.Styled as Html exposing (Html)
import Markdown.Block exposing (Block)
import Markdown.Parser
import OptimizedDecoder exposing (Decoder)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path
import Shared exposing (Msg(..), SharedMsg(..))
import SplatTypes exposing (Msg(..))
import TailwindMarkdownRenderer
import View exposing (View)


type alias Msg =
    SplatTypes.Msg


type alias Model =
    ()



-- type Msg
--     = NoOp


type alias RouteParams =
    { splat : List String }


page : PageWithState RouteParams Data Model Msg
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildWithSharedState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Cmd Msg )
init _ _ _ =
    ( (), Cmd.none )


subscriptions :
    Maybe PageUrl
    -> routeParams
    -> Path.Path
    -> Model
    -> Shared.Model
    -> Sub Msg
subscriptions _ _ _ _ _ =
    Sub.none


update :
    PageUrl
    -> Maybe Browser.Navigation.Key
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Cmd Msg, Maybe Shared.Msg )
update _ _ _ _ msg model =
    case msg of
        ClickButton ->
            ( model, Cmd.none, Just (SharedMsg LogConsole) )


routes : DataSource (List RouteParams)
routes =
    contentGlob
        |> DataSource.map
            (List.map
                (\{ subPath, slug } ->
                    RouteParams (subPath ++ [ slug ])
                )
            )
        -- add in empty route for index
        |> DataSource.map (\x -> x ++ [ RouteParams [] ])


data : RouteParams -> DataSource Data
data routeParams =
    pageBody routeParams.splat Data


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    { metadata : ContentMetadata
    , body : Shared.Model -> List (Html Msg)
    }


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ sharedModel model static =
    { title = static.data.metadata.title
    , body = static.data.body sharedModel
    }


pageBody :
    List String
    ->
        (ContentMetadata
         ->
            (Shared.Model
             -> List (Html Msg)
            )
         -> value
        )
    -> DataSource value
pageBody splat constructor =
    Glob.expectUniqueMatch (findBySplat splat)
        |> DataSource.andThen
            (withFrontmatter
                constructor
                frontmatterDecoder
                TailwindMarkdownRenderer.render
            )


withFrontmatter :
    (frontmatter -> (Shared.Model -> List (Html Msg)) -> value)
    -> Decoder frontmatter
    -> (List Block -> DataSource (Shared.Model -> List (Html Msg)))
    -> String
    -> DataSource value
withFrontmatter constructor frontmatterDecoder2 renderer filePath =
    DataSource.map2 constructor
        (File.onlyFrontmatter
            frontmatterDecoder2
            filePath
        )
        ((File.bodyWithoutFrontmatter
            filePath
            |> DataSource.andThen
                (\rawBody ->
                    rawBody
                        |> Markdown.Parser.parse
                        |> Result.mapError (\_ -> "Couldn't parse markdown.")
                        |> DataSource.fromResult
                )
         )
            |> DataSource.andThen
                renderer
        )


frontmatterDecoder : OptimizedDecoder.Decoder ContentMetadata
frontmatterDecoder =
    OptimizedDecoder.map5 ContentMetadata
        (OptimizedDecoder.field "title" OptimizedDecoder.string)
        (OptimizedDecoder.field "description" OptimizedDecoder.string)
        (OptimizedDecoder.field "published"
            (OptimizedDecoder.string
                |> OptimizedDecoder.andThen
                    (\isoString ->
                        case Date.fromIsoString isoString of
                            Ok date ->
                                OptimizedDecoder.succeed date

                            Err error ->
                                OptimizedDecoder.fail error
                    )
            )
        )
        (OptimizedDecoder.field "draft" OptimizedDecoder.bool
            |> OptimizedDecoder.maybe
            |> OptimizedDecoder.map (Maybe.withDefault False)
        )
        (OptimizedDecoder.field "rss" OptimizedDecoder.bool
            |> OptimizedDecoder.maybe
            |> OptimizedDecoder.map (Maybe.withDefault False)
        )


findBySplat : List String -> Glob String
findBySplat splat =
    if splat == [] then
        Glob.literal "content/index.md"

    else
        Glob.succeed identity
            |> Glob.captureFilePath
            |> Glob.match (Glob.literal "content/")
            |> Glob.match (Glob.literal (String.join "/" splat))
            |> Glob.match
                (Glob.oneOf
                    ( ( "", () )
                    , [ ( "/index", () ) ]
                    )
                )
            |> Glob.match (Glob.literal ".md")


type alias ContentMetadata =
    { title : String
    , description : String
    , published : Date
    , draft : Bool
    , rss : Bool
    }


contentGlob : DataSource (List Content)
contentGlob =
    Glob.succeed Content
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/")
        |> Glob.capture Glob.recursiveWildcard
        |> Glob.match (Glob.literal "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match
            (Glob.oneOf
                ( ( "", () )
                , [ ( "/index", () ) ]
                )
            )
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource


type alias Content =
    { filePath : String
    , subPath : List String
    , slug : String
    }
