package haxeFormatter;

import haxeFormatter.Config;
import hxParser.Converter;
import hxParser.HxParser;
import hxParser.ParseTree;
import hxParser.Printer;
import util.Result;

class Formatter {
    public static function formatFile(file:File, ?config:Config):Result<String> {
        if (config == null)
            config = {};
        applyDefaultSettings(config);
        new Processor(config).walkFile(file, Root);
        return Success(Printer.print(file));
    }

    public static function formatClassFields(classFields:Array<ClassField>, ?config:Config):Result<String> {
        if (config == null)
            config = {};
        applyDefaultSettings(config);
        var processor = new Processor(config);
        var buf = new StringBuf();
        for (field in classFields) {
            processor.walkClassField(field, Root);
            buf.add(Printer.print(field));
        }
        return Success(buf.toString());
    }

    public static function formatSource(source:String, entryPoint:EntryPoint = File, ?config:Config):Result<String> {
        var parsed = HxParser.parse(source, entryPoint);
        return switch (parsed) {
            case Success(d):
                switch (entryPoint) {
                    case File: formatFile(Converter.convertResultToFile(d), config);
                    case ClassFields: formatClassFields(Converter.convertResultToClassFields(d), config);
                    case ClassDecl: /* TODO */ null;
                }
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