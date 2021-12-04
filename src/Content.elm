module Content exposing
    ( Content
    , ContentMetadata
    , allMetadata
    , allPosts
    , contentGlob
    , frontmatterDecoder
    , pageBody
    , withFrontmatter
    )

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob exposing (Glob)
import Date exposing (Date)
import Html.Styled as Html exposing (Html)
import Markdown.Block exposing (Block)
import Markdown.Parser
import OptimizedDecoder exposing (Decoder)
import Route
import Shared
import TailwindMarkdownRenderer


type alias Content =
    { filePath : String
    , subPath : List String
    , slug : String
    }


type alias FullPost =
    { route : Route.Route
    , metadata : ContentMetadata
    , content : String
    }


allPosts : DataSource.DataSource (List FullPost)
allPosts =
    contentGlob
        |> DataSource.map
            (\paths ->
                paths
                    |> List.map
                        (\{ filePath, subPath, slug } ->
                            DataSource.map3 FullPost
                                (DataSource.succeed <|
                                    Route.SPLAT__
                                        { splat =
                                            subPath ++ [ slug ]
                                        }
                                )
                                (File.onlyFrontmatter frontmatterDecoder filePath)
                                (File.bodyWithoutFrontmatter filePath)
                        )
            )
        |> DataSource.resolve
        |> DataSource.map
            (\articles ->
                articles
                    |> List.filterMap
                        (\{ route, metadata, content } ->
                            if metadata.rss then
                                Just (FullPost route metadata content)

                            else
                                Nothing
                        )
            )
        |> DataSource.map
            (List.sortBy
                (\{ metadata } -> -(Date.toRataDie metadata.published))
            )


allMetadata : DataSource.DataSource (List ( Route.Route, ContentMetadata ))
allMetadata =
    contentGlob
        |> DataSource.map
            (\paths ->
                paths
                    |> List.map
                        (\{ filePath, subPath, slug } ->
                            DataSource.map2 Tuple.pair
                                (DataSource.succeed <|
                                    Route.SPLAT__
                                        { splat =
                                            subPath ++ [ slug ]
                                        }
                                )
                                (File.onlyFrontmatter frontmatterDecoder filePath)
                        )
            )
        |> DataSource.resolve
        |> DataSource.map
            (\articles ->
                articles
                    |> List.filterMap
                        (\( route, metadata ) ->
                            if metadata.rss then
                                Just ( route, metadata )

                            else
                                Nothing
                        )
            )
        |> DataSource.map
            (List.sortBy
                (\( route, metadata ) -> -(Date.toRataDie metadata.published))
            )


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


withFrontmatter :
    (frontmatter -> (Shared.Model -> List (Html msg)) -> value)
    -> Decoder frontmatter
    -> (List Block -> DataSource (Shared.Model -> List (Html msg)))
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


type alias ContentMetadata =
    { title : String
    , description : String
    , published : Date
    , draft : Bool
    , rss : Bool
    }


pageBody :
    List String
    ->
        (ContentMetadata
         ->
            (Shared.Model
             -> List (Html msg)
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
