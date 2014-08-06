{-|

Helpers for carma-models dictionaries used in legacy CRUD triggers.

TODO: Refactor this module to a single typed helper for new
dictionaries.

-}

module Snaplet.DbLayer.Triggers.Util
    ( getCRRLabel
    )

where

import           Data.Text (Text)
import qualified Data.Text.Read as T

import           Snap.Snaplet.PostgresqlSimple ((:.)(..), Only(..))

import           Data.Model as Model
import           Data.Model.Sql
import qualified Carma.Model.ClientRefusalReason as CRR
import qualified Carma.Model.Service as Service

import           Snaplet.DbLayer.Triggers.Dsl
import           Snaplet.DbLayer.Triggers.Types
import           Snaplet.DbLayer.Types
import           Snaplet.DbLayer.Util


-- | Fetch label of @clientCancelReason@ field of a service.
getCRRLabel :: MonadTrigger m b => ObjectId -> m b Text
getCRRLabel caseId = do
  c <- get caseId $ fieldName Service.clientCancelReason
  case T.decimal c of
    Right (c', _) ->
        do
          [Only l :. ()] <- liftDb $ selectDb $
                            CRR.label :. CRR.ident `eq` Ident c'
          return l
    Left _ -> return c
