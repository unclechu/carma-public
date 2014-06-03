{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE DoAndIfThenElse #-}

{-|

File upload helpers and @attachment@ model handling.

TODO Use @attachment@ model permissions in upload handlers.

-}

module Snaplet.FileUpload
    ( fileUploadInit
    , FileUpload(..)
    , doUpload
    , doUploadTmp
    , withUploads
    , oneUpload
    , getAttachmentPath
    )

where

import Control.Lens
import Control.Monad
import Control.Concurrent.STM

import Data.Aeson as A hiding (Object)
import Data.Attoparsec.Text as P

import Data.Either
import Data.Functor
import qualified Data.Map as M
import Data.Maybe
import Data.Configurator
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Char8 as B8
import Data.Digest.Pure.MD5 (md5)
import qualified Data.HashSet as HS
import Database.PostgreSQL.Simple.SqlQQ
import Data.Char
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import System.Directory
import System.FilePath
import System.IO

import Snap (gets, liftIO)
import Snap.Core hiding (path)
import Snap.Snaplet
import Snap.Snaplet.PostgresqlSimple hiding (field)
import Snap.Util.FileUploads

import Snaplet.Auth.Class
import Snaplet.Messenger.Class

import qualified Snaplet.DbLayer as DB
import qualified Utils.NotDbLayer as NDB
import Snaplet.DbLayer.Types

import Util as U


data FileUpload b = FU { cfg      :: UploadPolicy
                       , tmp      :: FilePath
                       , finished :: FilePath
                       -- ^ Root directory of finished uploads.
                       , db       :: Lens' b (Snaplet (DbLayer b))
                       , locks    :: TVar (HS.HashSet ByteString)
                       -- ^ Set of references to currently locked
                       -- instances.
                       }


routes :: (HasAuth b, HasMsg b) => [(ByteString, Handler b (FileUpload b) ())]
routes = [ (":model/bulk/:field",      method POST uploadBulk)
         , (":model/:id/:field",       method POST uploadInField)
         ]


-- | Lift a DbLayer handler action to FileUpload handler.
withDb :: Handler b (DbLayer b) a -> Handler b (FileUpload b) a
withDb = (gets db >>=) . flip withTop


-- | SQL query used to select attachment id by hash. Parametrized by
-- hash value.
hashToAid :: Query
hashToAid = [sql|SELECT id::text FROM attachmenttbl WHERE hash=?;|]


-- | A field of an instance to attach an attachment to.
type AttachmentTarget = (ModelName, ObjectId, FieldName)


-- | Upload a file, create a new attachment (an instance of
-- @attachment@ model), add references to it in a given set of other
-- instance fields (attachment targets) which depend on the filename.
-- Rename the saved file after reading attachment targets. Return the
-- created attachment object, lists of failed (left) and successful
-- (right) attachment targets, and a flag indicating that the file was
-- recognized as a duplicate. Target is unsuccessful if a referenced
-- instance does not exist.
--
-- The file is stored under @attachment/<newid>@ directory hierarchy
-- of finished uploads dir.
uploadInManyFields :: (HasAuth b, HasMsg b)
                   => (FilePath -> [AttachmentTarget])
                   -- ^ Convert the uploaded file name to a list of
                   -- fields in instances to attach the file to.
                   -> Maybe (FilePath -> FilePath)
                   -- ^ Change source file name when saving.
                   -> Handler b (FileUpload b)
                      (Object, [AttachmentTarget], [AttachmentTarget], Bool)
uploadInManyFields flds nameFun = do
  -- Store the file
  fPath <- oneUpload =<< doUpload =<< gets tmp
  let (_, fName) = splitFileName fPath

  hash <- liftIO $ md5 <$> BL.readFile fPath

  -- Check for duplicate files
  res <- withDb $ query hashToAid (Only $ show hash)
  (aid, dupe) <- case res of
    [] -> do
      -- Create empty attachment instance
      attach <- withDb $ DB.create "attachment" M.empty

      root <- gets finished
      let aid        = attach M.! "id"
          newDir     = root </> "attachment" </> B8.unpack aid
          newName    = (fromMaybe id nameFun) fName
      -- Move file to attachment/<aid>
      liftIO $ createDirectoryIfMissing True newDir >>
               copyFile fPath (newDir </> newName) >>
               removeFile fPath
      _ <- withDb $ DB.update "attachment" aid $
                    M.insert "hash" (stringToB $ show hash) $
                    M.singleton "filename" (stringToB newName)
      return (aid, False)
    (Only aid:_) -> return (aid, True)

  -- Attach to target field for existing instances, using the original
  -- filename
  let targets = flds fName
  results <-
      forM targets $ \t@(model, objId, field) -> do
          e <- withDb $ NDB.exists model objId
          if e
          then do
              attachToField model objId field $ B8.append "attachment:" aid
              return $ Right t
          else
              return $ Left t
  let (failedTargets, succTargets) = partitionEithers results

  -- Serve back full attachment instance
  obj <- withDb $ DB.read "attachment" aid

  return (obj, failedTargets, succTargets, dupe)


-- | Upload and attach a file (as in 'uploadInManyFields'), but read a
-- list of instance ids from the file name (@732,123,452-foo09.pdf@
-- reads to @[732, 123, 452]@; all non-digit characters serve as
-- instance id separators, no number past the first @-@ character are
-- read). @model@ and @field@ are read from request parameters.
--
-- Server response is a JSON object with four keys: @attachment@
-- contains an attachment object, @targets@ contains a list of triples
-- with attachment targets used, @unknown@ is a failed attachment
-- target list, @dupe@ is true if the file was a duplicate.
uploadBulk :: (HasAuth b, HasMsg b) => Handler b (FileUpload b) ()
uploadBulk = do
  -- 'Just' here, for these have already been matched by Snap router
  Just model <- getParam "model"
  Just field <- getParam "field"
  (obj, failedTargets, succTargets, dupe) <-
      uploadInManyFields
             (\fName -> map (\i -> (model, i, field)) (readIds fName))
             (Just cutIds)
  writeLBS $ A.encode $ A.object [ "attachment" A..= obj
                                 , "targets"    A..= succTargets
                                 , "unknown"    A..= failedTargets
                                 , "dupe"       A..= dupe
                                 ]
      where
        -- Read a list of decimal instance ids from a file name,
        -- skipping everything else.
        readIds :: FilePath -> [ObjectId]
        readIds fn =
            either (const []) (map $ stringToB . (show :: Int -> String)) $
            parseOnly (manyTill
                       (skipWhile (not . isDigit) >> decimal)
                       (char '-'))
            (T.pack fn)
        -- Cut out all ids from a filename prior to the first dash char.
        cutIds :: FilePath -> FilePath
        cutIds fp = if elem '-' fp
                    then tail $ dropWhile (/= '-') fp
                    else fp


-- | Upload and attach a file (as in 'uploadInManyFields') to a single
-- instance, given by @model@, @id@ and @field@ request parameters.
uploadInField :: (HasAuth b, HasMsg b) => Handler b (FileUpload b) ()
uploadInField = do
  Just model <- getParam "model"
  Just objId <- getParam "id"
  Just field <- getParam "field"
  (res, fails, _, _) <- uploadInManyFields (const [(model, objId, field)]) Nothing
  if null fails
  then writeLBS $ A.encode $ res
  else error $ "Failed to upload in field: " ++ (show fails)


-- | Return path to an attached file (prepended by finished uploads
-- dir).
getAttachmentPath :: ObjectId
                  -- ^ Attachment ID.
                  -> Handler b (FileUpload b) FilePath
getAttachmentPath aid = do
  obj <- withDb $ DB.read "attachment" aid
  fPath <- gets finished
  case M.lookup "filename" obj of
    Just fName -> return $
                  fPath </> "attachment" </>
                  B8.unpack aid </> bToString fName
    _ -> error $ "Broken attachment" ++ B8.unpack aid


-- | Append a reference of form @attachment:213@ to a field of another
-- instance, which must exist. This handler is thread-safe.
attachToField :: (HasAuth b, HasMsg b)
              => ModelName
              -- ^ Name of target instance model.
              -> ObjectId
              -- ^ Id of target instance.
              -> FieldName
              -- ^ Field name in target instance.
              -> ByteString
              -- ^ A reference to an attachment instance to be added
              -- in a field of target instance.
              -> Handler b (FileUpload b) ()
attachToField modelName instanceId field ref = do
  l <- gets locks
  -- Lock the field or wait for lock release
  liftIO $ atomically $ do
    hs <- readTVar l
    if HS.member lockName hs
    then retry
    else writeTVar l (HS.insert lockName hs)
  -- Append new ref to the target field
  oldRefs <- NDB.fieldProj field <$> (withDb $ NDB.read modelName instanceId)
  let newRefs = addRef oldRefs ref
  _  <- withDb $ NDB.update modelName instanceId
        (NDB.fieldPatch field (A.String $ T.decodeUtf8 newRefs))
  -- Unlock the field
  liftIO $ atomically $ do
    hs <- readTVar l
    writeTVar l (HS.delete lockName hs)
  return ()
    where
      addRef ""    r = r
      addRef val   r = BS.concat [val, ",", r]
      lockName = BS.concat [modelName, ":", instanceId, "/", field]


-- | Error which occured when processing an uploaded part.
type PartError = (PartInfo, PolicyViolationException)


-- | Process all files in the request and collect results. Files are
-- deleted after the handler runs. To permanently store the uploaded
-- files, copy them in the handler.
withUploads :: (PartInfo -> FilePath -> IO a)
            -- ^ Handler for successfully uploaded files.
            -> Handler b (FileUpload b) [Either PartError a]
withUploads proceed = do
  tmpDir <- gets tmp
  cfg <- gets cfg
  fns <- handleFileUploads tmpDir cfg (const $ partPol cfg) $
    liftIO . mapM (\(info, r) -> case r of
      Right tmp -> Right <$> proceed info tmp
      Left e    -> return $ Left (info, e)
      )
  return fns


-- | Helper which extracts first non-erroneous element from
-- 'withUploads' result or raises error if there's no such element.
oneUpload :: [Either PartError a] -> Handler b (FileUpload b) a
oneUpload res =
    case partitionEithers res of
      (_,         (f:_)) -> return f
      (((_, e):_), _   ) -> error $ T.unpack $ policyViolationExceptionReason e
      ([], [])           -> error "No uploaded parts provided"


-- | Store files from the request, return full paths to the uploaded
-- files. Original file names are preserved.
doUpload :: FilePath
         -- ^ Store files in this directory (relative to finished
         -- uploads path)
         -> Handler b (FileUpload b) [Either PartError FilePath]
doUpload relPath = do
  root <- gets finished
  let path = root </> relPath
  withUploads $ \info tmp ->
      do
        let justFname = U.bToString . fromJust $ partFileName info
            newPath = path </> justFname
        createDirectoryIfMissing True path
        copyFile tmp newPath
        return newPath


-- | Store files from the request in the temporary dir, return pairs
-- @(original file name, path to file)@.
doUploadTmp :: Handler b (FileUpload b) [Either PartError (FilePath, FilePath)]
doUploadTmp = do
  tmpDir <- gets tmp
  withUploads $ \info tmp ->
      do
        let name = case partFileName info of
                     Just fn -> U.bToString fn
                     Nothing -> takeFileName tmp
        (newPath, _) <- openTempFile tmpDir name
        copyFile tmp newPath
        return (name, newPath)


partPol :: UploadPolicy -> PartUploadPolicy
partPol = allowWithMaximumSize . getMaximumFormInputSize


fileUploadInit :: (HasAuth b, HasMsg b) =>
                  Lens' b (Snaplet (DbLayer b))
               -> SnapletInit b (FileUpload b)
fileUploadInit db =
    makeSnaplet "fileupload" "fileupload" Nothing $ do
      cfg      <- getSnapletUserConfig
      maxFile  <- liftIO $ lookupDefault 100  cfg "max-file-size"
      minRate  <- liftIO $ lookupDefault 1000 cfg "min-upload-rate"
      kickLag  <- liftIO $ lookupDefault 10   cfg "min-rate-kick-lag"
      inact    <- liftIO $ lookupDefault 20   cfg "inactivity-timeout"
      tmp      <- liftIO $ require            cfg "tmp-path"
      finished <- liftIO $ require            cfg "finished-path"
      -- we need some values in bytes
      let maxFile' = maxFile * 1024
          minRate' = minRate * 1024
          -- Every thread is for a single file
          maxInp   = 1
          pol      = setProcessFormInputs         True
                     $ setMaximumFormInputSize maxFile'
                     $ setMaximumNumberOfFormInputs maxInp
                     $ setMinimumUploadRate    minRate'
                     $ setMinimumUploadSeconds kickLag
                     $ setUploadTimeout        inact
                       defaultUploadPolicy
      addRoutes routes
      l <- liftIO $ newTVarIO HS.empty
      return $ FU pol tmp finished db l
