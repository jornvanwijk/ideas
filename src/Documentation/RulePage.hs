-----------------------------------------------------------------------------
-- Copyright 2011, Open Universiteit Nederland. This file is distributed
-- under the terms of the GNU General Public License. For more information,
-- see the file "LICENSE.txt", which is included in the distribution.
-----------------------------------------------------------------------------
-- |
-- Maintainer  :  bastiaan.heeren@ou.nl
-- Stability   :  provisional
-- Portability :  portable (depends on ghc)
--
-----------------------------------------------------------------------------
module Documentation.RulePage (makeRulePages) where

import Common.Library
import Common.Utils (Some(..))
import Control.Monad
import Data.List
import Documentation.DefaultPage
import Documentation.ExercisePage (idboxHTML)
import Documentation.RulePresenter
import Service.DomainReasoner
import Service.RulesInfo (rewriteRuleToFMP, collectExamples, ExampleMap)
import Text.HTML
import Text.OpenMath.FMP
import Text.OpenMath.Object
import qualified Data.Map as M
import qualified Text.XML as XML

data ExItem a = EI (Exercise a) (ExampleMap a)

makeRulePages :: String -> DomainReasoner ()
makeRulePages dir = do
   exs <- getExercises
   let exMap = M.fromList
          [ (getId ex, Some (EI ex (collectExamples ex)))
          | Some ex <- exs
          ]
       ruleMap = M.fromListWith (++)
          [ (getId r, [Some ex])
          | Some ex <- exs
          , r <- ruleset ex
          ]
   forM_ (M.toList ruleMap) $ \(ruleId, list) ->
      case list of
         [] -> return ()
         Some ex:_ ->
            case M.findWithDefault noExamples (getId ex) exMap of
               Some (EI ex1 e) ->
                  forM_ (getRule ex1 ruleId) $ \r ->
                     generatePageAt lev dir (ruleFile ruleId) $
                        rulePage ex1 e usedIn r
          where
            noExamples = Some (EI ex M.empty)
            lev        = length (qualifiers ruleId) + 1
            usedIn     = sortBy compareId [ getId ex1 | Some ex1 <- list ]

rulePage :: Exercise a -> ExampleMap a -> [Id] ->  Rule (Context a) -> HTMLBuilder
rulePage ex exMap usedIn r = do
   idboxHTML "rule" (getId r)
   let idList = text . intercalate ", " . map showId
   para $ table False
      [ [bold $ text "Buggy", text $ showBool (isBuggy r)]
      , [bold $ text "Rewrite rule", text $ showBool (isRewriteRule r)]
      , [bold $ text "Siblings", idList $ ruleSiblings r]
      ]
   when (isRewriteRule r) $ para $
      ruleToHTML (Some ex) r

   h3 "Used in exercises"
   let f a = link (up upn ++ exercisePageFile a) (tt $ text $ show a)
       upn = length (qualifiers r) + 1
   ul $ map f usedIn

   -- Examples
   let ys  = M.findWithDefault [] (getId r) exMap
   unless (null ys) $ do
      h3 "Examples"
      forM_ (take 3 ys) $ \(a, b) -> para $ divClass "step" $ pre $ do
         forTerm ex (inContext ex a)
         forStep upn (getId r, mempty)
         forTerm ex (inContext ex b)

   -- FMPS
   let xs = getRewriteRules (transformation r)
   unless (null xs) $ do
      h3 "Formal Mathematical Properties"
      forM_ xs $ \(Some rr) -> para $ do
         let fmp = rewriteRuleToFMP (not $ isBuggy r) rr
         highlightXML False $ XML.makeXML "FMP" $
            XML.builder (omobj2xml (toObject fmp))

forStep :: Int -> (Id, Environment) -> HTMLBuilder
forStep n (i, env) = do
      spaces 3
      text "=>"
      space
      let target = up n ++ ruleFile i
          make | null (description i) = link target
               | otherwise = titleA (description i) . link target
      make (text (unqualified i))
      br
      unless (noBindings env) $ do
         spaces 6
         text (show env)
         br

forTerm :: Exercise a -> Context a -> HTMLBuilder
forTerm ex ca = do
   text (prettyPrinterContext ex ca)
   br