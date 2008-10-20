-----------------------------------------------------------------------------
-- Copyright 2008, Open Universiteit Nederland. This file is distributed 
-- under the terms of the GNU General Public License. For more information, 
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-- (todo)
--
-----------------------------------------------------------------------------
module Domain.RelationAlgebra.Exercises (cnfExercise) where

import Prelude hiding (repeat)
import Domain.RelationAlgebra.Formula
import Domain.RelationAlgebra.Generator
import Domain.RelationAlgebra.Strategies
import Domain.RelationAlgebra.Rules
import Domain.RelationAlgebra.Parser
import Common.Apply
import Common.Exercise
import Common.Context
import Common.Uniplate (somewhereM)
import Common.Parsing (fromRanged)
import Common.Rewriting (treeDiff)
import Common.Strategy hiding (not)
import Common.Transformation

cnfExercise :: Exercise RelAlg
cnfExercise = makeExercise
   { identifier    = "cnf"
   , domain        = "relationalg"
   , description   = "To conjunctive normal form"
   , status        = Experimental
   , parser        = either Left (Right . fromRanged) . parseRelAlg
   , prettyPrinter = ppRelAlg
   , equivalence   = probablyEqual -- isEquivalent
   , ruleset       = map liftRuleToContext (relAlgRules ++ buggyRelAlgRules)
   , strategy      = toCNF
   , differences   = treeDiff
   , ordering      = compare
   , finalProperty = ready (ruleset cnfExercise)
   , generator     = templateGenerator 1
   , suitableTerm  = \p -> let n = stepsRemaining (emptyPrefix toCNF) (inContext p)
                           in n >= 2 && n <= 4
   }

{- cnfExerciseSimple :: Exercise RelAlg
cnfExerciseSimple = cnfExercise
   { identifier  = "cnf-simple"
   , description = description cnfExercise ++ " (simple)"
   , strategy    = label "Apply rules exhaustively" $ repeat $ somewhere $ alternatives $ ruleset cnfExercise
   } -}
   
ready :: [Rule (Context a)] -> a -> Bool
ready rs = null . applyAll (alternatives $ filter (not . isBuggyRule) rs) . inContext