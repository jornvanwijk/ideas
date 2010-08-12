-----------------------------------------------------------------------------
-- Copyright 2010, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-----------------------------------------------------------------------------
module Service.ProblemDecomposition 
   ( problemDecomposition
   , Reply(..), replyToXML
   , ReplyIncorrect(..)
   , replyType, replyTypeSynonym
   ) where

import Common.Classes
import Common.Context
import Common.Derivation
import Common.Exercise
import Common.Strategy hiding (not, repeat, fail)
import Common.Transformation 
import Common.Utils
import Control.Monad
import Data.Maybe
import Service.ExercisePackage
import Service.State
import Service.Types
import Text.OpenMath.Object
import Text.XML hiding (name)

problemDecomposition :: Monad m => Maybe Id -> State a -> Maybe a -> m (Reply a)
problemDecomposition msloc (State pkg mpr requestedTerm) answer 
   | isNothing $ subStrategy sloc (strategy ex) =
        fail "request error: invalid location for strategy"
   | otherwise =
   let pr = fromMaybe (emptyPrefix $ strategy ex) mpr in
         case (runPrefixLocation sloc pr requestedTerm, maybe Nothing (Just . inContext ex) answer) of            
            ([], _) -> fail "strategy error: not able to compute an expected answer"
            (answers, Just answeredTerm)
               | not (null witnesses) ->
                    return $ Ok ReplyOk
                       { repOk_Location = nextTaskLocation (strategy ex) sloc $ 
                                             fromMaybe top $ nextMajorForPrefix newPrefix (fst $ head witnesses)
                       , repOk_Context  = show newPrefix ++ ";" ++ 
                                          show (getEnvironment $ fst $ head witnesses)
                       }
                  where 
                    witnesses   = filter (similarityCtx ex answeredTerm . fst) $ take 1 answers
                    newPrefix   = snd (head witnesses)            
            ((expected, prefix):_, maybeAnswer) ->
                    return $ Incorrect ReplyIncorrect
                       { repInc_Location   = subTaskLocation (strategy ex) sloc loc
                       , repInc_Expected   = fromJust (fromContext expected)
                       , repInc_Arguments  = args
                       , repInc_Equivalent = maybe False (equivalenceContext ex expected) maybeAnswer
                       }
             where
               (loc, args) = fromMaybe (top, []) $ 
                                firstMajorInPrefix pr prefix requestedTerm
 where
   ex   = exercise pkg
   top  = getId (strategy ex)
   sloc = fromMaybe top msloc
   
similarityCtx :: Exercise a -> Context a -> Context a -> Bool
similarityCtx ex a b = fromMaybe False $
   liftM2 (similarity ex) (fromContext a) (fromContext b)

-- | Continue with a prefix until a certain strategy location is reached. At least one
-- major rule should have been executed
runPrefixLocation :: Id -> Prefix a -> a -> [(a, Prefix a)]
runPrefixLocation loc p0 =
   concatMap (check . f) . derivations . 
   cutOnStep (stop . lastStepInPrefix) . prefixTree p0
 where
   f d = (last (terms d), if isEmpty d then p0 else last (steps d))
   stop (Just (Exit info)) = getId info == loc
   stop _ = False
 
   check result@(a, p)
      | null rules            = [result]
      | all isMinorRule rules = runPrefixLocation loc p a
      | otherwise             = [result]
    where
      rules = stepsToRules $ drop (length $ prefixToSteps p0) $ prefixToSteps p

firstMajorInPrefix :: Prefix a -> Prefix a -> a -> Maybe (Id, Args)
firstMajorInPrefix p0 prefix a = do
   let steps = prefixToSteps prefix
       newSteps = drop (length $ prefixToSteps p0) steps
   is <- firstLocation newSteps
   return (is, argumentsForSteps a newSteps)
 where
   firstLocation :: HasId l => [Step l a] -> Maybe Id
   firstLocation [] = Nothing
   firstLocation (Enter info:RuleStep r:_) | isMajorRule r = Just (getId info)
   firstLocation (_:rest) = firstLocation rest
 
argumentsForSteps :: a -> [Step l a] -> Args
argumentsForSteps a = flip rec a . stepsToRules
 where
   rec [] _ = []
   rec (r:rs) a
      | isMinorRule r  = concatMap (rec rs) (applyAll r a)
      | applicable r a = let ds = map (\(Some d) -> labelArgument d) (getDescriptors r)
                         in maybe [] (zip ds) (expectedArguments r a)
      | otherwise      = []
 
nextMajorForPrefix :: Prefix a -> a -> Maybe Id
nextMajorForPrefix p0 a = do
   (_, p1)  <- safeHead $ runPrefixMajor p0 a
   let steps = prefixToSteps p1
   rec (reverse steps)
 where
   rec [] = Nothing
   rec (Enter info:_) = Just (getId info)
   rec (Exit  info:_) = Just (getId info)
   rec (_:rest)       = rec rest
   
-- Copied from TypedAbstractService: clean me up
runPrefixMajor :: Prefix a -> a -> [(a, Prefix a)]
runPrefixMajor p0 = 
   map f . derivations . cutOnStep (stop . lastStepInPrefix) . prefixTree p0
 where
   f d = (last (terms d), if isEmpty d then p0 else last (steps d))
   stop (Just (RuleStep r)) = isMajorRule r
   stop _ = False
        
------------------------------------------------------------------------
-- Data types for replies

data Reply a = Ok (ReplyOk a) | Incorrect (ReplyIncorrect a)

data ReplyOk a = ReplyOk
   { repOk_Location :: Id
   , repOk_Context  :: String
   }
   
data ReplyIncorrect a = ReplyIncorrect
   { repInc_Location   :: Id
   , repInc_Expected   :: a
   , repInc_Arguments  :: Args
   , repInc_Equivalent :: Bool
   }

type Args = [(String, String)]

------------------------------------------------------------------------
-- Conversion functions to XML

replyToXML :: (a -> OMOBJ) -> Reply a -> XMLBuilder
replyToXML toOpenMath reply =
   case reply of
      Ok r        -> replyOkToXML r
      Incorrect r -> replyIncorrectToXML toOpenMath r 

replyOkToXML :: ReplyOk a -> XMLBuilder
replyOkToXML r = element "correct" $ do
   element "location" (text $ show $ repOk_Location r)
   element "context"  (text $ repOk_Context r)

replyIncorrectToXML :: (a -> OMOBJ) -> ReplyIncorrect a -> XMLBuilder
replyIncorrectToXML toOpenMath r = element "incorrect" $ do
   element "location"   (text $ show $ repInc_Location r)
   element "expected"   (builder $ omobj2xml $ toOpenMath $ repInc_Expected r)
   element "equivalent" (text $ show $ repInc_Equivalent r)
   
   unless (null $ repInc_Arguments r) $
       let f (x, y) = element "elem" $ do 
              "descr" .=. x 
              text y
       in element "arguments" $ mapM_ f (repInc_Arguments r)

replyType :: Type a (Reply a)
replyType = useSynonym replyTypeSynonym

replyTypeSynonym :: TypeSynonym a (Reply a)
replyTypeSynonym = typeSynonym "DecompositionReply" to from tp
 where
   to (Left (a, b)) = 
      Ok (ReplyOk a b)
   to (Right (a, b, c, d)) =
      Incorrect (ReplyIncorrect a b c d)
   
   from (Ok (ReplyOk a b)) = Left (a, b)
   from (Incorrect (ReplyIncorrect a b c d)) =
      Right (a, b, c, d)
   
   tp  =  tuple2 Id String
      :|: tuple4 Id Term argsTp Bool

   argsTp = List (Pair String String)