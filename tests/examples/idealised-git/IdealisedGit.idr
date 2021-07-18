module IdealisedGit

import Collie

git : Command
git = MkCommand
  { name = "idealised-git"
  , description = """
A distributed revision control system with an emphasis on speed,
data integrity, and support for distributed, non-linear workflows
"""
  , subcommands = MkCommands [<
                    record { description = "Add file contents to the index"}
                      (basic "add" $ lotsOf filePath)
                  , record { description = "Clone a repository into a new directory" }
                      (basic "clone" url)
                  ]
  , modifiers = []
  , arguments = lotsOf filePath
  }
  where
    gitPush : Command
    gitPush = MkCommand
      { name = "push"
      , description = "Update remote refs along with associated objects"
      , subcommands = []
      , modifiers = [
            "--force" ::= flag """
Usually, the command refuses to update a remote ref that
is not an ancestor of the local ref used to overwrite it. This
flag disables the check. This can cause the remote repository
to lose commits; use it with care.
"""
          ]
      , arguments = none
      }


main : IO Builtin.Unit
main = do putStrLn "ok"