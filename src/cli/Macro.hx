package cli;

class Macro
{
    public static macro function getVersion(): haxe.macro.Expr
    {
        var gitDescribe = new sys.io.Process('git', ['tag', '--points-at', 'HEAD']);
        var tag = gitDescribe.stdout.readAll().toString().trim();
        if (gitDescribe.exitCode() != 0 || tag == "")
        {
            var gitRevParseHEAD = new sys.io.Process('git', ['rev-parse', '--short', 'HEAD']);
            if (gitRevParseHEAD.exitCode() != 0)
            {
                throw("`git rev-parse HEAD` failed: " + gitRevParseHEAD.stderr.readAll().toString());
            }
            var commitHash = gitRevParseHEAD.stdout.readLine();
            return macro $v{commitHash};
        }
        return macro $v{tag};
    }
}
