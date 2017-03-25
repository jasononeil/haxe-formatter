package haxeFormatter;

import sys.FileSystem;
import sys.io.File;
using StringTools;

class Cli {
    static function main() {
        new Cli();
    }

    var config:Config;

    function new() {
        var args = Sys.args();
        var paths = [];
        var argHandler = hxargs.Args.generate([
            @doc("File or directory with .hx files to format (multiple allowed).")
            ["-s", "--source"] => function(path:String) paths.push(path),

            @doc("Only reindent.")
            ["--indent"] => function(whitespace:String) config = {
                baseConfig: Noop,
                indent: {
                    whitespace: "\t"
                }
            },
        ]);
        argHandler.parse(args);
        if (args.length == 0) {
            Sys.println("Haxe Formatter");
            Sys.println(argHandler.getDoc());
            Sys.exit(0);
        }
        run(paths);
    }

    function run(paths:Array<String>) {
        for (path in paths) {
            if (FileSystem.isDirectory(path))
                run([for (file in FileSystem.readDirectory(path)) '$path/$file']);
            else
                try formatFile(path)
            catch (e:Any) error(path, e);
        }
    }

    function formatFile(file:String) {
        if (!file.endsWith(".hx"))
            return;
        var formatted = Formatter.formatSource(File.getContent(file), config);
        switch (formatted) {
            case Success(data):
                File.saveContent(file, data);
                Sys.println('Formatted $file');
            case Failure(reason):
                error(file, reason);
        }
    }

    function error(file:String, reason:String) {
        Sys.stderr().writeString('Could not format "$file": $reason\n');
    }
}