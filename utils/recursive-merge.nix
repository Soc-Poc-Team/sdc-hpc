{ }:
#
# This function allows merging two attSets that might contain lists without overriding
# 
# nix-repl> b = { ab = ["World"]; ba = 2; };
# nix-repl> recursiveMerge a b
# {
#   ab = [ ... ];
#   ba = 2;
# }
# nix-repl> :p recursiveMerge a b
# {
#   ab = [
#     "Hello"
#     "World"
#   ];
#   ba = 2;
# }
#

let
  recursiveMerge =
    a: b:
    if builtins.isAttrs a && builtins.isAttrs b then
      let
        keys = builtins.attrNames (a // b);
      in
      builtins.listToAttrs (
        map (key: {
          name = key;
          value =
            if a ? ${key} && b ? ${key} then
              recursiveMerge a.${key} b.${key}
            else if b ? ${key} then
              b.${key}
            else
              a.${key};
        }) keys
      )
    else if builtins.isList a && builtins.isList b then
      a ++ b
    else
      a;
in
{
  inherit recursiveMerge;
}
