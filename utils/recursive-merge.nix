{ }:
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
