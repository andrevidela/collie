module Collie.Parser

import Data.List
import Data.String
import Data.Either
import Data.Maybe
import Data.Fun
import Data.Record.Ordered
import Collie.Core

public export
parseCommand : (cmd : Command) -> List String ->  ParsedCommand cmd ->
  Error (ParsedCommand cmd)

public export
parseModifier : (cmd : Command) -> {modName : String} ->
  (pos : modName `IsField` cmd.modifiers) -> (rest : List String) ->
  ParsedCommand cmd ->
  (factory : ParsedModifier (field pos) -> Error (ParsedModifiers cmd.modifiers)) ->
  Error (ParsedCommand cmd)

parseCommand cmd [] old = pure old
parseCommand cmd ("--" :: xs) old = do
  u <- cmd.arguments.parse old.arguments xs
  pure $ record { arguments = u} old

parseCommand cmd (x :: xs) old
  = case x `isField` cmd.modifiers of
      No  _   => do u <- old.arguments.update x
                    parseCommand cmd xs $ record { arguments = u} old
      Yes pos => parseModifier cmd pos xs old (old.modifiers.update pos)

parseModifier  cmd pos rest old factory with (field pos)
 parseModifier cmd pos rest old factory | MkFlag   flg = do
    mods <- factory True
    parseCommand cmd rest $ record { modifiers = mods } old
 parseModifier cmd pos rest old factory | MkOption opt
   = case rest of
       []      => throwE "Missing argument for option \{modName}"
       x :: xs => do args <- (opt.project "arguments").parser x
                     mods <- factory args
                     parseCommand cmd xs $ record {modifiers = mods} old

public export
parse : (cmd : Command) -> List String -> Error $ ParseTree cmd
parse cmd [] = pure (Here initParsedCommand)
parse cmd xs@("--" :: _) = Here <$> parseCommand cmd xs initParsedCommand
parse cmd ys@(x :: xs) = case x `isField` cmd.subcommands of
                           Yes pos => There pos <$> parse (field pos) xs
                           No  _   => Here <$> parseCommand cmd ys initParsedCommand