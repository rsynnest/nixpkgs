args @ { fetchurl, ... }:
rec {
  baseName = "clump-2-3-tree";
  version = "clump-20160825-git";

  description = "System lacks description";

  deps = [ args."acclimation" ];

  src = fetchurl {
    url = "http://beta.quicklisp.org/archive/clump/2016-08-25/clump-20160825-git.tgz";
    sha256 = "1mngxmwklpi52inihkp4akzdi7y32609spfi70yamwgzc1wijbrl";
  };

  packageName = "clump-2-3-tree";

  asdFilesToKeep = ["clump-2-3-tree.asd"];
  overrides = x: x;
}
/* (SYSTEM clump-2-3-tree DESCRIPTION System lacks description SHA256
    1mngxmwklpi52inihkp4akzdi7y32609spfi70yamwgzc1wijbrl URL
    http://beta.quicklisp.org/archive/clump/2016-08-25/clump-20160825-git.tgz
    MD5 5132d2800138d435ef69f7e68b025c8f NAME clump-2-3-tree FILENAME
    clump-2-3-tree DEPS ((NAME acclimation FILENAME acclimation)) DEPENDENCIES
    (acclimation) VERSION clump-20160825-git SIBLINGS
    (clump-binary-tree clump-test clump) PARASITES NIL) */
