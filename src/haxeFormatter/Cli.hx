package haxeFormatter;

import sys.FileSystem;
import sys.io.File;
using StringTools;

class Cli {
    static function main() {
        new Cli();
    }

    function new() {
        var args = Sys.args();
        var paths = [];
        var argHandler = hxargs.Args.generate([
            @doc("File or directory with .hx files to format (multiple allowed).")
            ["-s", "--source"] => function(path:String) paths.push(path),
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
            if (!FileSystem.isDirectory(path))
                formatFile(path);
            else
                run([for (file in FileSystem.readDirectory(path)) '$path/$file']);
        }
    }

    function formatFile(file:String) {
        if (!file.endsWith(".hx"))
            return;
        var formatted = Formatter.formatSource(File.getContent(file));
        switch (formatted) {
            case Success(data):
                File.saveContent(file, data);
                Sys.println('Formatted $file');
            case Failure(reason):
                Sys.stderr().writeString('Could not format "$file": $reason\n');
        }
    }
}