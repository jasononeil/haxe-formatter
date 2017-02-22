package haxeFormatter;

import haxeFormatter.Configuration;
import hxParser.HxParser;
import hxParser.JsonParser;
import util.Result;

class Formatter {
    public static function format(code:String, config:Configuration):Result<String> {
        var parsed = HxParser.parse(code);
        var data:JNodeBase = null;
        switch (parsed) {
            case Success(d): data = d;
            case Failure(reason): Failure(reason);
        }

        applyDefaultSettings(config);
        var tree:Tree = JsonParser.parse(data);
        tree = new Processor(config).process(tree);
        return Success(Printer.print(tree));
    }

    // TODO: figure out some better way to have default settings...
    static function applyDefaultSettings(config:Configuration) {
        if (config.imports == null)
            config.imports = { sort: true };
        else if (config.imports.sort == null)
            config.imports.sort = true;

        var typeHintColonDefault = { before: Remove, after: Remove };
        if (config.padding == null)
            config.padding = { typeHintColon: typeHintColonDefault };

        var padding = config.padding;
        if (padding.typeHintColon == null)
            padding.typeHintColon = typeHintColonDefault;
    }
}