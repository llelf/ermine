{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
--------------------------------------------------------------------
-- |
-- Module    :  Ermine.Syntax.Pat
-- Copyright :  (c) Edward Kmett
-- License   :  BSD3
-- Maintainer:  Edward Kmett <ekmett@gmail.com>
-- Stability :  experimental
-- Portability: non-portable
--
--------------------------------------------------------------------
module Ermine.Syntax.Pat
  ( Pat(..)
  , Alt(..)
  , bitraverseAlt
  ) where

import Bound
import Control.Lens
import Control.Applicative
import Data.Bitraversable
import Data.Foldable
import Ermine.Syntax
import Ermine.Syntax.Global
import Ermine.Syntax.Literal
import Ermine.Syntax.Scope

-- | Patterns used by 'Term' and 'Core'.
data Pat t
  = VarP
  | SigP t             -- ^ not used by 'Core'
  | WildcardP
  | AsP (Pat t)
  | StrictP (Pat t)
  | LazyP (Pat t)
  | LitP Literal
  | ConP Global [Pat t]
  | TupP [Pat t]
  deriving (Eq, Show, Functor, Foldable, Traversable)

-- | One alternative of a core expression
data Alt t f a = Alt !(Pat t) !(Scope Int f a)
  deriving (Eq,Show,Functor,Foldable,Traversable)

instance Bound (Alt t) where
  Alt p b >>>= f = Alt p (b >>>= f)

instance Monad f => BoundBy (Alt t f) f where
  boundBy f (Alt p b) = Alt p (boundBy f b)

-- | Helper function for traversing both sides of an 'Alt'.
bitraverseAlt :: (Bitraversable k, Applicative f) => (t -> f t') -> (a -> f b) -> Alt t (k t) a -> f (Alt t' (k t') b)
bitraverseAlt f g (Alt p b) = Alt <$> traverse f p <*> bitraverseScope f g b

instance Tup (Pat t) where
  tupled = prism TupP $ \p -> case p of TupP ps -> Right ps ; _ -> Left p
