{-|

Contract model processing for portal screen (per-subprogram field
permissions and hacks).

-}

module Snaplet.SiteConfig.SpecialPermissions
    ( stripContract
    , FilterType(..)
    )

where

import           Data.Aeson as Aeson
import           Data.Maybe
import qualified Data.Map as M
import           Data.ByteString (ByteString)
import           Data.Pool

import           Control.Applicative

import           Database.PostgreSQL.Simple (Query, query)
import           Database.PostgreSQL.Simple.SqlQQ
import           Database.PostgreSQL.Simple.ToField

import           Snap
import           Snap.Snaplet.Auth hiding (Role)
import qualified Snap.Snaplet.Auth as Snap (Role(..))

import           Carma.Model.Role as Role

import           Snaplet.Auth.Class
import           Snaplet.Auth.PGUsers
import           Snaplet.SiteConfig.Models
import           Snaplet.SiteConfig.Config

import           AppHandlers.Util
import           Util

q :: Query
q = [sql|
     SELECT contractField,
     (case ? when true then 't' else 'f' end)
     FROM "SubProgramContractPermission"
     WHERE contractfield IS NOT NULL
     AND parent = ?
     |]

data FilterType = Form | Table

instance ToField FilterType where
  toField Form = toField $ PT "showform"
  toField Table = toField $ PT "showtable"

stripContract :: HasAuth b =>
                 Model
              -> ByteString
              -- ^ SubProgram id.
              -> FilterType
              -> Handler b (SiteConfig b) Model
stripContract model sid flt = do
  pg    <- gets pg_search
  perms <- liftIO $ withResource pg $ getPerms sid
  Just mcu <- withAuth currentUser
  mcu'     <- withLens db $ replaceMetaRolesFromPG mcu
  let procField = if (Snap.Role $ identFv Role.partner) `elem` userRoles mcu'
                  then reqField
                  else id
  return model{fields = map procField $ filterFields perms (fields model)}
    where
      reqField f =
          if name f /= "comment"
          then f{meta = Just $ M.insert "required" (Aeson.Bool True) $
                 fromMaybe M.empty $ meta f}
          else f
      getPerms progid conn = M.fromList <$>
        (query conn q (flt, progid) :: IO [(ByteString, ByteString)])
      filterFields perms flds = filter (isCanShow perms) flds
      isCanShow perms f  = fromMaybe False $ check flt perms (name f)
      check Form _ "dixi"        = return True
      check Form _ "committer"   = return True
      check Form _ "isActive"    = return True
      check Form _ "ctime"       = return True
      check Table _ "id"         = return True
      check _ _ "subprogram" = return True
      check _ perms name         = M.lookup name perms >>= return . ("t" ==)
