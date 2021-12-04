module TailwindMarkdownRenderer exposing (render, renderAll)

import Css
import DataSource exposing (DataSource)
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attr exposing (css)
import List.Extra as Extra
import Markdown.Block as Block exposing (Block)
import Markdown.Html
import Markdown.Renderer
import Shared exposing (Model, TestId(..), Version(..))
import SyntaxHighlight
import Tailwind.Breakpoints as Bp
import Tailwind.Utilities as Tw


render : List Block -> DataSource (Shared.Model -> List (Html msg))
render blocks =
    blocks
        |> Markdown.Renderer.render engine
        |> Result.map
            (\blockViews model ->
                blockViews
                    |> renderAll model
            )
        |> DataSource.fromResult


engine : Markdown.Renderer.Renderer (Model -> Html.Html msg)
engine =
    { heading = heading
    , paragraph =
        \children model ->
            p [ css [ Tw.mx_3, Tw.mb_3, Bp.md [ Tw.mx_0 ] ] ]
                (renderAll model children)
    , blockQuote =
        \children model ->
            p
                [ css
                    [ Bp.md
                        [ Tw.border
                        , Tw.border_solid
                        , Tw.border
                        , Tw.rounded
                        , Tw.bg_white
                        , Tw.shadow_lg
                        , Tw.italic
                        , Tw.my_6
                        ]
                    , Tw.px_6
                    , Tw.py_4
                    ]
                ]
                (renderAll model children)
    , html =
        Markdown.Html.oneOf
            [ Markdown.Html.tag "row"
                (\children model ->
                    div
                        [ css
                            [ Tw.flex
                            , Tw.flex_wrap
                            , Tw.place_content_evenly
                            , Tw.space_x_1
                            ]
                        ]
                        (renderAll model
                            children
                        )
                )
            , Markdown.Html.tag "image"
                (\src desc _ _ ->
                    img
                        [ css [ Tw.object_scale_down, Tw.max_w_xs ]
                        , Attr.src
                            src
                        , Attr.alt desc
                        ]
                        []
                )
                |> Markdown.Html.withAttribute "src"
                |> Markdown.Html.withAttribute "desc"
            , Markdown.Html.tag "test"
                (\id version children model ->
                    let
                        test =
                            Extra.find
                                (\x -> (x.testId |> (\(TestId y) -> y)) == id)
                                model.tests
                                |> Maybe.map .version
                    in
                    case ( version, test ) of
                        ( "A", Just A ) ->
                            div [ css [ Tw.w_full ] ]
                                (renderAll model
                                    children
                                )

                        ( "B", Just B ) ->
                            div [ css [ Tw.w_full ] ]
                                (renderAll model
                                    children
                                )

                        _ ->
                            div [ css [ Tw.hidden ] ] []
                )
                |> Markdown.Html.withAttribute "id"
                |> Markdown.Html.withAttribute "version"
            ]
    , text = \children _ -> text children
    , codeSpan = \_ _ -> div [] []
    , strong =
        \children model ->
            strong [ css [ Tw.font_bold ] ]
                (renderAll model children)
    , emphasis =
        \children model ->
            em [ css [ Tw.italic ] ]
                (renderAll model children)
    , hardLineBreak = \_ -> br [] []
    , link =
        \{ destination } body model ->
            a
                [ Attr.href destination
                , css
                    [ Tw.underline
                    , Tw.text_blue_600
                    , Css.visited [ Tw.text_purple_800 ]
                    ]
                ]
                (renderAll model body)
    , image =
        \image _ ->
            case image.title of
                Just _ ->
                    img
                        [ css [ Tw.object_scale_down, Tw.w_full ]
                        , Attr.src
                            image.src
                        , Attr.alt image.alt
                        ]
                        []

                Nothing ->
                    img
                        [ css [ Tw.object_scale_down, Tw.w_full ]
                        , Attr.src
                            image.src
                        , Attr.alt image.alt
                        ]
                        []
    , unorderedList =
        \items model ->
            ul
                [ css
                    [ Tw.list_disc
                    , Tw.ml_10
                    , Tw.mr_2
                    , Tw.mb_3
                    , Bp.md
                        [ Tw.mr_0
                        ]
                    ]
                ]
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Block.ListItem task children ->
                                    let
                                        checkbox =
                                            case task of
                                                Block.NoTask ->
                                                    text ""

                                                Block.IncompleteTask ->
                                                    input
                                                        [ Attr.disabled True
                                                        , Attr.checked False
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []

                                                Block.CompletedTask ->
                                                    input
                                                        [ Attr.disabled True
                                                        , Attr.checked True
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []
                                    in
                                    li [] (checkbox :: renderAll model children)
                        )
                )
    , orderedList =
        \startingIndex items model ->
            ol
                (case startingIndex of
                    1 ->
                        [ Attr.start startingIndex
                        , css
                            [ Tw.list_decimal
                            , Tw.ml_10
                            ]
                        ]

                    _ ->
                        []
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            li []
                                (renderAll model
                                    itemBlocks
                                )
                        )
                )
    , codeBlock = codeBlock
    , thematicBreak = \_ -> hr [] []
    , table = \children model -> div [] (renderAll model children)
    , tableHeader = \children model -> div [] (renderAll model children)
    , tableBody = \children model -> div [] (renderAll model children)
    , tableRow = \children model -> div [] (renderAll model children)
    , tableCell = \_ children model -> div [] (renderAll model children)
    , tableHeaderCell = \_ _ _ -> div [] []
    , strikethrough =
        \children model -> Html.del [] (renderAll model children)
    }


rawTextToId rawText =
    rawText
        |> String.split " "
        |> String.join "-"
        |> String.toLower


heading :
    { level : Block.HeadingLevel
    , rawText : String
    , children :
        List (Model -> Html.Html msg)
    }
    -> Model
    -> Html.Html msg
heading { level, rawText, children } model =
    let
        commonCss =
            [ Tw.font_header
            , Tw.text_gray_800
            , Tw.tracking_tight
            , Tw.text_center
            , Tw.mx_3
            , Bp.md [ Tw.text_left, Tw.mx_0 ]
            ]
    in
    case level of
        Block.H1 ->
            h1
                [ css
                    ([ Tw.text_4xl
                     , Tw.mt_6
                     , Tw.mb_4
                     , Tw.font_sans
                     , Tw.font_bold
                     ]
                        ++ commonCss
                    )
                ]
                (renderAll model children)

        Block.H2 ->
            h2
                [ Attr.id (rawTextToId rawText)
                , Attr.attribute "name" (rawTextToId rawText)
                , css
                    ([ Tw.text_3xl
                     , Tw.mt_6
                     , Tw.mb_2
                     , Tw.font_sans
                     , Tw.font_bold
                     ]
                        ++ commonCss
                    )
                ]
                (renderAll model children)

        Block.H3 ->
            h3
                [ Attr.id (rawTextToId rawText)
                , Attr.attribute "name" (rawTextToId rawText)
                , css
                    ([ Tw.text_2xl
                     , Tw.mt_6
                     , Tw.mb_3
                     , Tw.font_sans
                     , Tw.font_bold
                     ]
                        ++ commonCss
                    )
                ]
                (renderAll model children)

        _ ->
            (case level of
                Block.H1 ->
                    h1

                Block.H2 ->
                    h2

                Block.H3 ->
                    h3

                Block.H4 ->
                    h4

                Block.H5 ->
                    h5

                Block.H6 ->
                    h6
            )
                [ css
                    ([ Tw.text_lg
                     , Tw.mt_4
                     ]
                        ++ commonCss
                    )
                ]
                (renderAll model children)


renderAll : model -> List (model -> view) -> List view
renderAll model =
    List.map ((|>) model)


codeBlock : { body : String, language : Maybe String } -> Shared.Model -> Html.Html msg
codeBlock details _ =
    SyntaxHighlight.elm details.body
        |> Result.map (SyntaxHighlight.toBlockHtml (Just 1))
        |> Result.map Html.fromUnstyled
        |> Result.withDefault (Html.pre [] [ Html.code [] [ Html.text details.body ] ])
