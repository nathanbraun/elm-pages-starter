module Page.SPLAT__ exposing (Data, Model, Msg, page)

import Content exposing (ContentMetadata)
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Html.Styled as Html exposing (Html)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { splat : List String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    Content.contentGlob
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
    Content.pageBody routeParams.splat Data


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
    -> StaticPayload Data RouteParams
    -> View Msg
view _ sharedModel static =
    { title = static.data.metadata.title
    , body = static.data.body sharedModel
    }