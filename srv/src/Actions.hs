{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE FlexibleInstances #-}

module Actions where

import Control.Applicative
import Control.Monad
import Control.Monad.Instances () -- instance Functor Either
import Control.Monad.Trans
import Control.Monad.Trans.State

import Data.Text (Text)
import qualified Data.Text as T
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B8
import qualified Data.ByteString.Lazy as LB (readFile)

import Data.Set (Set)
import qualified Data.Set as S
import Data.Map (Map)
import qualified Data.Map as M
import Data.Maybe (fromMaybe)

import Data.Aeson as Aeson
import Data.Aeson.TH
import Data.Attoparsec.ByteString.Lazy (parse, Result(..))

import Snap.Snaplet (Handler)
import Snap.Snaplet.RedisDB (runRedisDB)
import Snap.Snaplet.Redson.Internals
import Snap.Snaplet.Redson.Snapless.Metamodel
import qualified Snap.Snaplet.Redson.Snapless.CRUD as CRUD



data Action = Action
  { a'on  :: Map ByteString (Set FieldValue)
  , a'new :: [Map FieldName Template]
  , a'set :: Map ByteString Template
  , a'del :: Bool
  }


instance FromJSON Action where
  parseJSON (Object o) = Action
    <$> o .:  "on"
    <*> o .:? "new" .!= []
    <*> o .:? "set" .!= M.empty
    <*> o .:? "del" .!= False
  parseJSON _ = mzero


newtype Template = Template [TmpPart] deriving Show
data TmpPart = Str Text | Expr Expr deriving Show

data Expr
  = Var ByteString
  | TimeOffset Int -- UTCDiff
  | Call ByteString Expr
  deriving Show


instance FromJSON Template where
  parseJSON (String s) = parseTemplate s

parseTemplate :: (Applicative m, Functor m) => Text -> m Template
parseTemplate s = Template <$> goS s
    where
      goS "" = pure []
      goS s  = let (x,xs) = T.breakOn "{{" s
               in  (Str x :) <$> goE (stripPrefix "{{" xs)

      goE "" = pure []
      goE s  = let (x,xs) = T.breakOn "}}" s
               in  (:) <$> (Expr <$> expr x)
                       <*> goS (stripPrefix "}}" xs)

      stripPrefix p s = fromMaybe s $ T.stripPrefix p s

      expr s = pure $ Var ""


parseActions :: FilePath -> IO (Either String [Action])
parseActions fName = do
  res <- parse Aeson.json' <$> LB.readFile fName
  return $ case res of
    Done _ jsn -> case Aeson.fromJSON jsn of
      Success actions -> Right actions
      Error err -> Left err
    err -> Left $ show err


compileAction :: Action -> HookMap b
compileAction (Action {..})
  = joinHooks
    [ hook2map path
      $ chkFieldVal vals
      $ withEvalContext
--        $ updateSelf a'set
        $ mapM createAction a'new
--        $ if a'del then archive else nop
    | (path,vals) <- M.toList a'on
    ]


-- FIXME: translate 'service' pseudomodel to set of true service models
hook2map :: ByteString -> Hook b -> HookMap b
hook2map p
  = M.singleton model
  . M.singleton field . (:[])
  where
    [model,field] = B8.split '.' p -- FIXME

chkFieldVal :: Set FieldValue -> Hook b -> Hook b
chkFieldVal vals h = \v commit ->
  if S.member v vals
    then h v commit
    else return commit

data EvalContext = EvalContext
  { objects   :: Map ModelName (Map FieldName ByteString)
  , objectIds :: Map ModelName ByteString -- InstanceId?
  }
emptyContext = EvalContext M.empty M.empty

type EvalStateMonad b a = StateT EvalContext (Handler b (Redson b)) a


redisRead m = runRedisDB database . CRUD.read m
redisUpdate m cxt = do
  let longId = objectIds cxt M.! m
  let obj    = objects   cxt M.! m
  let [modelName, intId] = B8.split ':' longId
  Right _ <- runRedisDB database
        $ CRUD.update modelName intId obj [] -- FIXME: indices from model
  return ()


cxtAddObject key longId cxt = do
  let [modelName, intId] = B8.split ':' longId
  Right obj <- redisRead modelName intId
  cxtAddObject' key longId obj cxt

cxtAddObject' key longId obj cxt = 
  return $ cxt 
    { objects = M.insert key obj $ objects cxt
    , objectIds = M.insert key longId $ objectIds cxt
    }
  

withEvalContext :: EvalStateMonad b a -> Hook b
withEvalContext f = \v commit -> do
  currentModel <- getModelName
  currentId <- getInstanceId
  let currentFullId = B8.concat [currentModel, ":", currentId]

  Right this <- redisRead currentModel currentId
  let this' = M.union commit this

  cxt <- case currentModel of
    "action" -> return emptyContext
        >>= cxtAddObject  "service" (this' M.! "serviceId")
        >>= cxtAddObject  "case"    (this' M.! "caseId")
        >>= cxtAddObject' "action"  currentFullId this'
    _ -> return emptyContext -- some service: e.g. towage or tech
        >>= cxtAddObject  "case"    (this' M.! "parentId")
        >>= cxtAddObject' "service" currentFullId this'

  -- TODO: insert cxt [#now,#currentUser,#dict(,)]

  cxt' <- execStateT f cxt

  -- NB: we have race conditions if two users change same
  -- instance simultaneously. Hope this is impossible due to
  -- business processes constraints.
  -- FIXME: update only changed fields
  redisUpdate "case" cxt'
  redisUpdate "service" cxt'

  let thisName = if currentModel == "action" then "action" else "service"
  return $ objects cxt' M.! thisName


evalTemplate _ = B8.pack . show 

createAction :: Map FieldName Template -> EvalStateMonad b ()
createAction actionTemplate = do
  cxt <- get
  let action = M.map (evalTemplate cxt)
        $ M.union actionTemplate $ M.fromList
          -- FIXME: quasiquotation?
          [("caseId",    Template [Str "case:", Expr (Var "case.id")])
          ,("serviceId", Template [Expr (Var "service.name")
                                  , Str ":", Expr (Var "service.id")])
          ,("ctime",     Template [Expr (Var "#.now")])
          ]
  Right actionId <- lift
        $ runRedisDB database
        $ CRUD.create "action" action [] -- FIXME: get indices from cxt.models

  let actionId' = B8.append "action:" actionId
  let caseActions = maybe actionId'
        (\actions -> B8.concat [actions, ",", actionId'])
        $  M.lookup "actions" $ objects cxt M.! "case"
  put $ cxt
    { objects = M.update
        (Just . M.insert "actions" caseActions)
        "case" $ objects cxt
    }

joinHooks :: [HookMap b] -> HookMap b
joinHooks = M.unionsWith (M.unionWith (++))

compileActions :: FilePath -> IO (Either String (HookMap b))
compileActions fName
  = fmap (joinHooks . map compileAction)
  <$> parseActions fName