package haxeFormatter;

import hxParser.JsonParser;
import hxParser.HxParser;
import util.Result;

class Formatter {
    public static function format(code:String, config:Configuration):Result<String> {
        var parsed = HxParser.parse(code);
        var data:JNodeBase = null;
        switch (parsed) {
            case Success(d): data = d;
            case Failure(reason): Failure(reason);
        }

        var tree:Tree = JsonParser.parse(data);
        tree = new Processor(config).process(tree);
        return Success(Printer.print(tree));
    }
}