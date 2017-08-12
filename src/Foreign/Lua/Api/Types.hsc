{-
Copyright © 2007-2012 Gracjan Polak
Copyright © 2012-2016 Ömer Sinan Ağacan
Copyright © 2017 Albert Krewinkel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
-}
{-# LANGUAGE CPP                        #-}
{-# LANGUAGE ForeignFunctionInterface   #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-|
Module      : Foreign.Lua.Types.Core
Copyright   : © 2007–2012 Gracjan Polak,
                2012–2016 Ömer Sinan Ağacan,
                2017 Albert Krewinkel
License     : MIT
Maintainer  : Albert Krewinkel <tarleb+hslua@zeitkraut.de>
Stability   : beta
Portability : ForeignFunctionInterface, GeneralizedNewtypeDeriving

The core Lua types, including mappings of Lua types to Haskell.
-}
module Foreign.Lua.Api.Types where

import Prelude hiding (EQ, LT)
import Data.Int (#{type LUA_INTEGER})
import Foreign.C (CInt)
import Foreign.Ptr (FunPtr, Ptr)

#include "lua.h"

-- | An opaque structure that points to a thread and indirectly (through the
-- thread) to the whole state of a Lua interpreter. The Lua library is fully
-- reentrant: it has no global variables. All information about a state is
-- accessible through this structure.
--
-- Synonym for @lua_State *@. See <https://www.lua.org/manual/5.3/#lua_State lua_State>.
newtype LuaState = LuaState (Ptr ()) deriving (Eq)

-- |  Type for C functions.
--
-- In order to communicate properly with Lua, a C function must use the
-- following protocol, which defines the way parameters and results are passed:
-- a C function receives its arguments from Lua in its stack in direct order
-- (the first argument is pushed first). So, when the function starts,
-- @'gettop'@ returns the number of arguments received by the function. The
-- first argument (if any) is at index 1 and its last argument is at index
-- @gettop@. To return values to Lua, a C function just pushes them onto the
-- stack, in direct order (the first result is pushed first), and returns the
-- number of results. Any other value in the stack below the results will be
-- properly discarded by Lua. Like a Lua function, a C function called by Lua
-- can also return many results.
--
-- See <https://www.lua.org/manual/5.3/manual.html#lua_CFunction lua_CFunction>.
type CFunction = FunPtr (LuaState -> IO NumResults)

-- |  The type of integers in Lua.
--
-- By default this type is @'Int64'@, but that can be changed to different
-- values in lua. (See @LUA_INT_TYPE@ in @luaconf.h@.)
--
-- See <https://www.lua.org/manual/5.3/manual.html#lua_Integer lua_Integer>.
type LuaInteger = #{type LUA_INTEGER}

-- |  The type of floats in Lua.
--
-- By default this type is @'Double'@, but that can be changed in Lua to a
-- single float or a long double. (See @LUA_FLOAT_TYPE@ in @luaconf.h@.)
--
-- See <https://www.lua.org/manual/5.3/manual.html#lua_Number lua_Number>.
type LuaNumber = #{type LUA_NUMBER}


--
-- LuaBool
--

-- | Boolean value returned by a Lua C API function. This is a @'CInt'@ and
-- interpreted as @'False'@ iff the value is @0@, @'True'@ otherwise.
newtype LuaBool = LuaBool CInt deriving Eq

-- | Convert a @'LuaBool'@ to a Haskell @'Bool'@.
fromLuaBool :: LuaBool -> Bool
fromLuaBool (LuaBool 0) = False
fromLuaBool _           = True

-- | Convert a Haskell @'Bool'@ to a @'LuaBool'@.
toLuaBool :: Bool -> LuaBool
toLuaBool True  = LuaBool 1
toLuaBool False = LuaBool 0


--
-- * Type of Lua values
--

-- | Enumeration used as type tag.
-- See <https://www.lua.org/manual/5.3/manual.html#lua_type lua_type>.
data Type
  = TypeNone           -- ^ non-valid stack index
  | TypeNil            -- ^ type of lua's @nil@ value
  | TypeBoolean        -- ^ type of lua booleans
  | TypeLightUserdata  -- ^ type of light userdata
  | TypeNumber         -- ^ type of lua numbers. See @'LuaNumber'@
  | TypeString         -- ^ type of lua string values
  | TypeTable          -- ^ type of lua tables
  | TypeFunction       -- ^ type of functions, either normal or @'CFunction'@
  | TypeUserdata       -- ^ type of full user data
  | TypeThread         -- ^ type of lua threads
  deriving (Bounded, Eq, Ord, Show)

instance Enum Type where
  fromEnum TypeNone          = #{const LUA_TNONE}
  fromEnum TypeNil           = #{const LUA_TNIL}
  fromEnum TypeBoolean       = #{const LUA_TBOOLEAN}
  fromEnum TypeLightUserdata = #{const LUA_TLIGHTUSERDATA}
  fromEnum TypeNumber        = #{const LUA_TNUMBER}
  fromEnum TypeString        = #{const LUA_TSTRING}
  fromEnum TypeTable         = #{const LUA_TTABLE}
  fromEnum TypeFunction      = #{const LUA_TFUNCTION}
  fromEnum TypeUserdata      = #{const LUA_TUSERDATA}
  fromEnum TypeThread        = #{const LUA_TTHREAD}

  toEnum (#{const LUA_TNONE})          = TypeNone
  toEnum (#{const LUA_TNIL})           = TypeNil
  toEnum (#{const LUA_TBOOLEAN})       = TypeBoolean
  toEnum (#{const LUA_TLIGHTUSERDATA}) = TypeLightUserdata
  toEnum (#{const LUA_TNUMBER})        = TypeNumber
  toEnum (#{const LUA_TSTRING})        = TypeString
  toEnum (#{const LUA_TTABLE})         = TypeTable
  toEnum (#{const LUA_TFUNCTION})      = TypeFunction
  toEnum (#{const LUA_TUSERDATA})      = TypeUserdata
  toEnum (#{const LUA_TTHREAD})        = TypeThread
  toEnum n                             = error $ "Cannot convert (" ++ show n ++ ") to Type"

-- | Convert number to lua type.
toLuaType :: CInt -> Type
toLuaType = toEnum . fromIntegral

-- | Convert Lua type to its C representation.
fromLuaType :: Type -> CInt
fromLuaType = fromIntegral . fromEnum


--
-- * Relational Operator
--

-- | Lua comparison operations.
data RelationalOperator
  = EQ -- ^ Correponds to lua's equality (==) operator.
  | LT -- ^ Correponds to lua's strictly-lesser-than (<) operator
  | LE -- ^ Correponds to lua's lesser-or-equal (<=) operator
  deriving (Eq, Ord, Show)

-- | Convert relation operator to its C representation.
fromRelationalOperator :: RelationalOperator -> CInt
#if LUA_VERSION_NUMBER >= 502
fromRelationalOperator EQ = #{const LUA_OPEQ}
fromRelationalOperator LT = #{const LUA_OPLT}
fromRelationalOperator LE = #{const LUA_OPLE}
#else
fromRelationalOperator EQ = 0
fromRelationalOperator LT = 1
fromRelationalOperator LE = 2
#endif


--
-- * Status
--

-- | Lua status values.
data Status
  = OK        -- ^ success
  | Yield     -- ^ yielding / suspended coroutine
  | ErrRun    -- ^ a runtime rror
  | ErrSyntax -- ^ syntax error during precompilation
  | ErrMem    -- ^ memory allocation (out-of-memory) error.
  | ErrErr    -- ^ error while running the message handler.
  | ErrGcmm   -- ^ error while running a @__gc@ metamethod.
  deriving (Eq, Show)

-- | Convert C integer constant to @'LuaStatus'@.
toStatus :: StatusCode -> Status
-- LUA_OK is not defined in Lua 5.1
toStatus (StatusCode 0)                      = OK
toStatus (StatusCode #{const LUA_YIELD})     = Yield
toStatus (StatusCode #{const LUA_ERRRUN})    = ErrRun
toStatus (StatusCode #{const LUA_ERRSYNTAX}) = ErrSyntax
toStatus (StatusCode #{const LUA_ERRMEM})    = ErrMem
-- LUA_ERRGCMM did not exist in Lua 5.1; comes before LUA_ERRERR when defined
#if LUA_VERSION_NUMBER >= 502
toStatus (StatusCode #{const LUA_ERRGCMM})   = ErrGcmm
toStatus (StatusCode #{const LUA_ERRERR})    = ErrErr
#else
toStatus (StatusCode #{const LUA_ERRERR})    = ErrErr
#endif
toStatus (StatusCode n) = error $ "Cannot convert (" ++ show n ++ ") to LuaStatus"

-- | Integer code used to signal the status of a thread or computation.
-- See @'Status'@.
newtype StatusCode = StatusCode CInt deriving Eq

-- | Value or an error, using the convention that value below zero indicate an
-- error. Values greater than zero are used verbatim. The phantom type is
-- currently used for documentation only and has no effect.
type Failable a = CInt


--
-- * Gargabe Collection Control
--

-- | Enumeration used by @gc@ function.
data GCCONTROL
  = GCSTOP
  | GCRESTART
  | GCCOLLECT
  | GCCOUNT
  | GCCOUNTB
  | GCSTEP
  | GCSETPAUSE
  | GCSETSTEPMUL
  deriving (Enum, Eq, Ord, Show)

-- | A stack index
newtype StackIndex = StackIndex { fromStackIndex :: CInt }
  deriving (Enum, Eq, Num, Ord, Show)

--
-- Number of arguments and return values
--

-- | The number of arguments expected a function.
newtype NumArgs = NumArgs { fromNumArgs :: CInt }
  deriving (Eq, Num, Ord, Show)

-- | The number of results returned by a function call.
newtype NumResults = NumResults { fromNumResults :: CInt }
  deriving (Eq, Num, Ord, Show)
