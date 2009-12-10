-----------------------------------------------------------------------------
-- Copyright 2009, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-----------------------------------------------------------------------------
module Service.ServiceList (serviceList, Service(..), getService, evalService) where

import Common.Transformation
import qualified Common.Exercise as E
import Common.Utils (Some(..))
import Common.Exercise hiding (Exercise)
import Control.Monad.Error
import Service.ExerciseList (exercises)
import qualified Service.TypedAbstractService as S
import qualified Service.Diagnose as S
import Service.FeedbackText hiding (ExerciseText)
import Service.Types 
import Service.ProblemDecomposition
import Data.List (sortBy)

data Service a = Service 
   { serviceName        :: String
   , serviceDescription :: String
   , serviceFunction    :: TypedValue a
   }

------------------------------------------------------
-- Querying a service

serviceList :: [Service a]
serviceList =
   [ derivationS, allfirstsS, onefirstS, readyS
   , stepsremainingS, applicableS, applyS, generateS
   , submitS, diagnoseS
   , onefirsttextS, findbuggyrulesS
   , submittextS, derivationtextS
   , problemdecompositionS
   , exerciselistS, rulelistS
   ]

getService :: Monad m => String -> m (Service a)
getService txt =
   case filter ((==txt) . serviceName) serviceList of
      [hd] -> return hd
      []   -> fail $ "No service " ++ txt
      _    -> fail $ "Ambiguous service " ++ txt

evalService :: Monad m => Evaluator m inp out a -> Service a -> inp -> m out
evalService f = eval f . serviceFunction
   
------------------------------------------------------
-- Basic services

derivationS :: Service a
derivationS = Service "derivation" 
   "Returns one possible derivation (or: worked-out example) starting with the \
   \current expression. The first optional argument lets you configure the \
   \strategy, i.e., make some minor modifications to it. Rules used and \
   \intermediate expressions are returned in a list." $ 
   S.derivationNew ::: Maybe StrategyCfg :-> State :-> List (Tuple Rule Context)

allfirstsS :: Service a
allfirstsS = Service "allfirsts" 
   "Returns all next steps that are suggested by the strategy. See the \
   \onefirst service to get only one suggestion. For each suggestion, a new \
   \state, the rule used, and the location where the rule was applied are \
   \returned." $ 
   S.allfirsts ::: State :-> List (Triple Rule Location State)
        
onefirstS :: Service a
onefirstS = Service "onefirst" 
   "Returns a possible next step according to the strategy. Use the allfirsts \
   \service to get all possible steps that are allowed by the strategy. In \
   \addition to a new state, the rule used and the location where to apply \
   \this rule are returned." $ 
   S.onefirst ::: State :-> Elem (Triple Rule Location State)
  
readyS :: Service a
readyS = Service "ready" 
   "Test if the current expression is in a form accepted as a final answer. \
   \For this, the strategy is not used." $ 
   S.ready ::: State :-> Bool

stepsremainingS :: Service a
stepsremainingS = Service "stepsremaining" 
   "Computes how many steps are remaining to be done, according to the \
   \strategy. For this, only the first derivation is considered, which \
   \corresponds to the one returned by the derivation service." $
   S.stepsremaining ::: State :-> Int

applicableS :: Service a
applicableS = Service "applicable" 
   "Given a current expression and a location in this expression, this service \
   \yields all rules that can be applied at this location, regardless of the \
   \strategy." $ 
   S.applicable ::: Location :-> State :-> List Rule

applyS :: Service a
applyS = Service "apply" 
   "Apply a rule at a certain location to the current expression. If this rule \
   \was not expected by the strategy, we deviate from it. If the rule cannot \
   \be applied, this service call results in an error." $ 
   S.apply ::: Rule :-> Location :-> State :-> State

generateS :: Service a
generateS = Service "generate" 
   "Given an exercise code and a difficulty level (optional), this service \
   \returns an initial state with a freshly generated expression. The meaning \
   \of the difficulty level (an integer) depends on the exercise at hand." $ 
   S.generate ::: Exercise :-> Optional 5 Int :-> IO State

findbuggyrulesS :: Service a
findbuggyrulesS = Service "findbuggyrules" "" $ 
   S.findbuggyrules ::: State :-> Term :-> List Rule

submitS :: Service a
submitS = Service "submit" "" $ 
   S.submit ::: State :-> Term :-> Result

diagnoseS :: Service a
diagnoseS = Service "diagnose" "" $
   S.diagnose ::: State :-> Term :-> Diagnosis

------------------------------------------------------
-- Services with a feedback component

onefirsttextS :: Service a
onefirsttextS = Service "onefirsttext" "" $ 
   onefirsttext ::: ExerciseText :-> State :-> Maybe String :-> Elem (Triple Bool String State)

submittextS :: Service a
submittextS = Service "submittext" "" $ 
   submittext ::: ExerciseText :-> State :-> String :-> Maybe String :-> Elem (Triple Bool String State)

derivationtextS :: Service a
derivationtextS = Service "derivationtext" "" $ 
   derivationtext ::: ExerciseText :-> State :-> Maybe String :-> List (Tuple String Context)

------------------------------------------------------
-- Problem decomposition service

problemdecompositionS :: Service a
problemdecompositionS = Service "problemdecomposition" "" $
   problemDecomposition ::: State :-> StrategyLoc :-> Maybe Term :-> DecompositionReply

------------------------------------------------------
-- Reflective services
   
exerciselistS :: Service a
exerciselistS = Service "exerciselist" "" $
   allExercises ::: List (Quadruple (Tag "domain" String) (Tag "identifier" String) (Tag "description" String) (Tag "status" String))

rulelistS :: Service a
rulelistS = Service "rulelist" "" $ 
   allRules ::: Exercise :-> List (Triple (Tag "name" String) (Tag "buggy" Bool) (Tag "rewriterule" Bool))
      
allExercises :: [(String, String, String, String)]
allExercises  = map make $ sortBy cmp exercises
 where
   cmp e1 e2  = f e1 `compare` f e2
   f (Some ex) = exerciseCode ex
   make (Some ex) = 
      let code = exerciseCode ex 
      in (domain code, identifier code, description ex, show (status ex))

allRules :: E.Exercise a -> [(String, Bool, Bool)]
allRules = map make . ruleset
 where  
   make r  = (name r, isBuggyRule r, isRewriteRule r)