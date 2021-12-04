module Page.SPLAT__ exposing (Data, Model, Msg, page)

import Browser.Navigation
import Content exposing (ContentMetadata)
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Html.Styled as Html exposing (Html)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path
import Shared
import View exposing (View)


type alias Model =
    ()


type Msg
    = NoOp


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
    ( model, Cmd.none, Nothing )


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
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ sharedModel model static =
    { title = static.data.metadata.title
    , body = static.data.body sharedModel
    }
