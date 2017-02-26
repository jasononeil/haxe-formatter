package haxeFormatter;

import haxeFormatter.Config;
import hxParser.HxParser;
import hxParser.JsonParser;
import hxParser.Tree;
import hxParser.TreePrinter;
import util.Result;

class Formatter {
    public static function formatTree(tree:Tree, ?config:Config):Result<String> {
        if (config == null)
            config = {};
        applyDefaultSettings(config);
        tree = new Processor(config).process(tree, []);
        return Success(TreePrinter.print(tree));
    }

    public static function formatSource(source:String, ?entryPoint:EntryPoint, ?config:Config):Result<String> {
        var parsed = HxParser.parse(source, entryPoint);
        return switch (parsed) {
            case Success(d):
                var tree = JsonParser.parse(d);
                return formatTree(tree, config);
            case Failure(reason): Failure(reason);
        }
    }

    // TODO: figure out some better way to have default settings...
    static function applyDefaultSettings(config:Config) {
        if (config.imports == null)
            config.imports = {};
        if (config.imports.sort == null)
            config.imports.sort = true;

        if (config.padding == null)
            config.padding = {};

        var padding = config.padding;
        if (padding.typeHintColon == null)
            padding.typeHintColon = None;
    }
}