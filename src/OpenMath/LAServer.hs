module OpenMath.LAServer (respond, versionNr) where

import Domain.LinearAlgebra
import OpenMath.StrategyTable
import OpenMath.Request
import OpenMath.Reply
import OpenMath.ObjectParser
import Common.Transformation
import Common.Strategy hiding (not)
import Common.Assignment hiding (Incorrect)
import Data.Maybe
import Data.Char

respond :: Maybe String -> String
respond = replyInXML . maybe requestError (either parseError laServer . pRequest)

replyError :: String -> String -> Reply
replyError kind = Error . ReplyError kind

parseError :: String -> Reply
parseError   = replyError "parse error"

requestError :: Reply
requestError = replyError "request error" "no request found in \"input\""

(~=) :: String -> String -> Bool
xs ~= ys = let f = map toLower . filter (not . isSpace)
           in f xs == f ys 

laServer :: Request -> Reply
laServer req = 
   case [ ea | Entry _ ea@(ExprAssignment a) _ <- strategyTable, req_Strategy req ~= shortTitle a ] of
      [ExprAssignment a] -> laServerFor a req
      _ -> replyError "request error" "unknown strategy"
   
laServerFor :: IsExpr a => Assignment a -> Request -> Reply
laServerFor a req = 
   case (subStrategy (req_Location req) (strategy a), fromExpr $ req_Term req) of
   
      (Nothing, _) -> 
         replyError "request error" "invalid location for strategy"
         
      (_, Nothing) ->
         replyError "request error" ("invalid term for " ++ show (req_Strategy req))
         
      (Just subStrategy, Just requestedTerm) -> 
         
         case (applyAll subStrategy requestedTerm, maybe Nothing fromExpr $ req_Answer req) of
            ([], _) -> replyError "strategy error" "not able to compute an expected answer"
            
            (answers, Just answeredTerm)
               | any (equality a answeredTerm) answers ->
                    Ok $ ReplyOk
                       { repOk_Strategy = req_Strategy req
                       , repOk_Location = nextLocation answeredTerm (req_Location req) a
                       , repOk_Steps    = stepsRemaining reduceMatrixAssignment (inContext $ fromJust $ fromExpr $ fromJust $ req_Answer req)
                       }
                       
            (expected:_, maybeAnswer) ->
                    Incorrect $ ReplyIncorrect
                       { repInc_Strategy   = req_Strategy req
                       , repInc_Location   = req_Location req ++ subTask requestedTerm subStrategy
                       , repInc_Expected   = toExpr expected
                       , repInc_Steps      = stepsRemaining a requestedTerm
                       , repInc_Equivalent = maybe False (equivalence a expected) maybeAnswer
                       }
                     
subTask :: a -> LabeledStrategy a -> Location
subTask term subStrategy = 
   case firstLocation term subStrategy of
      Just (i:_) -> [i] -- one-level only
      _          -> []
      
nextLocation ::IsExpr a => a -> Location -> Assignment a -> Location
nextLocation term loc = maybe loc (rec loc) . firstLocation term . strategy
 where
   rec (i:is) (j:js)
      | i == j    = j : rec is js 
      | otherwise = [j]
   rec _ js       = take 1 js