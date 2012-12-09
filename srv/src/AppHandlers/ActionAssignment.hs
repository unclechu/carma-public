
module AppHandlers.ActionAssignment where

import Control.Monad
import Control.Applicative
import Data.String (fromString)

import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.ByteString.Char8 as B

import Snap
import Snap.Snaplet.Auth
import qualified Snaplet.DbLayer as DB
import Database.PostgreSQL.Simple
----------------------------------------------------------------------
import Application
import AppHandlers.CustomSearches
import AppHandlers.Util


assignQ :: Int -> AuthUser -> [Text] -> Query
assignQ pri usr logdUsers = fromString
  $  "UPDATE actiontbl SET assignedTo = '" ++ uLogin ++ "'"
  ++ "  WHERE id = (SELECT id FROM actiontbl"
  ++ "    WHERE closed = false"
  ++ "    AND   priority = '" ++ show pri ++ "'"
  ++ "    AND   duetime at time zone 'UTC' - now() < interval '30 minutes'"
  ++ "    AND   targetGroup = '" ++ roleStr uRole ++ "'"
  ++ "    AND   (assignedTo IS NULL"
  ++ "           OR assignedTo NOT IN ('" ++ logdUsersList ++ "'))"
  ++ "    ORDER BY duetime ASC"
  ++ "    LIMIT " ++ show pri ++ ")"
  ++ "  RETURNING id::text;"
  where
    uLogin = T.unpack $ userLogin usr
    uRole  = head $ userRoles usr
    roleStr (Role bs) = B.unpack bs
    logdUsersList = T.unpack $ T.intercalate "','" logdUsers


myActionsHandler :: AppHandler ()
myActionsHandler = do
  Just cUsr <- with auth currentUser
  logdUsers <- map (userLogin.snd) . Map.elems <$> addToLoggedUsers cUsr

  actIds1 <- withPG pg_actass (`query_` assignQ 1 cUsr logdUsers)
  actIds2 <- withPG pg_actass (`query_` assignQ 2 cUsr logdUsers)
  actIds3 <- withPG pg_actass (`query_` assignQ 3 cUsr logdUsers)
  let actIds = actIds1 ++ actIds2 ++ actIds3

  let uLogin = T.encodeUtf8 $ userLogin cUsr
  with db $ forM_ actIds $ \[actId] ->
      DB.update "action" actId
        $ Map.singleton "assignedTo" uLogin

  selectActions (Just "0") (Just uLogin) Nothing Nothing Nothing
    >>= writeJSON