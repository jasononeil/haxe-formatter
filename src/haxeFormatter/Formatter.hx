package haxeFormatter;

import haxeFormatter.Config;
import hxParser.Converter;
import hxParser.HxParser;
import hxParser.ParseTree;
import hxParser.Printer;
import util.Result;
import util.StructDefaultsMacro;

class Formatter {
    public static function formatFile(file:File, ?config:Config):Result<String> {
        config = applyDefaultSettings(config);
        new Processor(config).walkFile(file, Root);
        return Success(Printer.print(file));
    }

    public static function formatBlockElements(blockElements:Array<BlockElement>, ?config:Config):Result<String> {
        config = applyDefaultSettings(config);
        var processor = new Processor(config);
        var buf = new StringBuf();
        for (element in blockElements) {
            processor.walkBlockElement(element, Root);
            buf.add(Printer.print(element));
        }
        return Success(buf.toString());
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
                    case BlockElements: formatBlockElements(new Converter(d).convertResultToBlockElements(), config);
                }
            case Failure(reason): Failure(reason);
        }
    }

    static function applyDefaultSettings(config:Config):Config {
        config =
            if (config == null) {};
            else Reflect.copy(config);

        if (config.baseConfig == null)
            config.baseConfig = Default;

        var defaults = config.baseConfig.get();
        StructDefaultsMacro.applyDefaults(config, defaults);
        return config;
    }
}