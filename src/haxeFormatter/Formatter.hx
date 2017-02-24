package haxeFormatter;

import haxeFormatter.Configuration;
import hxParser.HxParser;
import hxParser.JsonParser;
import hxParser.Printer;
import hxParser.Tree;
import util.Result;

class Formatter {
    public static function formatTree(tree:Tree, ?config:Configuration):Result<String> {
        if (config == null)
            config = {};
        applyDefaultSettings(config);
        tree = new Processor(config).process(tree, []);
        return Success(Printer.print(tree));
    }

    public static function formatSource(source:String, ?entryPoint:EntryPoint, ?config:Configuration):Result<String> {
        var parsed = HxParser.parse(source, entryPoint);
        return switch (parsed) {
            case Success(d):
                var tree = JsonParser.parse(d);
                return formatTree(tree, config);
            case Failure(reason): Failure(reason);
        }
    }

    // TODO: figure out some better way to have default settings...
    static function applyDefaultSettings(config:Configuration) {
        if (config.imports == null)
            config.imports = {};
        if (config.imports.sort == null)
            config.imports.sort = true;

        var typeHintColonDefault = { before: Remove, after: Remove };
        if (config.padding == null)
            config.padding = { typeHintColon: typeHintColonDefault };

        var padding = config.padding;
        if (padding.typeHintColon == null)
            padding.typeHintColon = typeHintColonDefault;
    }
}