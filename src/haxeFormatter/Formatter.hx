package haxeFormatter;

import haxeFormatter.Config;
import hxParser.Converter;
import hxParser.HxParser;
import hxParser.ParseTree;
import hxParser.Printer;
import util.Result;

class Formatter {
    public static function formatFile(file:File, ?config:Config):Result<String> {
        config = applyDefaultSettings(config);
        new Processor(config).walkFile(file, Root);
        return Success(Printer.print(file));
    }

    public static function formatClassFields(classFields:Array<ClassField>, ?config:Config):Result<String> {
        config = applyDefaultSettings(config);
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
                    case File: formatFile(new Converter(d).convertResultToFile(), config);
                    case ClassFields: formatClassFields(new Converter(d).convertResultToClassFields(), config);
                    case ClassDecl: /* TODO */ null;
                }
            case Failure(reason): Failure(reason);
        }
    }

    // TODO: figure out some better way to have default settings...
    static function applyDefaultSettings(config:Config):Config {
        config =
            if (config == null) {};
            else Reflect.copy(config);

        if (config.baseConfig == null)
            config.baseConfig = Default;

        var defaults = config.baseConfig.get();

        if (config.imports == null)
            config.imports = defaults.imports;
        if (config.imports.sort == null)
            config.imports.sort = defaults.imports.sort;

        if (config.padding == null)
            config.padding = defaults.padding;

        var padding = config.padding;
        if (padding.typeHintColon == null)
            padding.typeHintColon = defaults.padding.typeHintColon;
        if (padding.functionTypeArrow == null)
            padding.functionTypeArrow = defaults.padding.functionTypeArrow;
        if (padding.binaryOperator == null)
            padding.binaryOperator = defaults.padding.binaryOperator;

        var binaryOperator = config.padding.binaryOperator;
        if (binaryOperator.defaultPadding == null)
            binaryOperator.defaultPadding = defaults.padding.binaryOperator.defaultPadding;
        if (binaryOperator.padded == null)
            binaryOperator.padded = defaults.padding.binaryOperator.padded;
        if (binaryOperator.unpadded == null)
            binaryOperator.unpadded = defaults.padding.binaryOperator.unpadded;

        return config;
    }
}