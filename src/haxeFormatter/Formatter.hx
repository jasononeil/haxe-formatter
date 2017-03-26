package haxeFormatter;

import haxeFormatter.Config;
import haxeFormatter.util.StructDefaultsMacro;
import haxeFormatter.walkers.Indenter;
import haxeFormatter.walkers.Processor;
import hxParser.Converter;
import hxParser.HxParser;
import hxParser.ParseTree;
import hxParser.Printer;
import hxParser.StackAwareWalker;
import util.Result;

class Formatter {
    public static function formatFile(file:File, ?config:Config):Result<String> {
        var walkers = createWalkers(config);
        for (walker in walkers)
            walker.walkFile(file, Root);
        return Success(Printer.print(file));
    }

    public static function formatBlockElements(blockElements:Array<BlockElement>, ?config:Config):Result<String> {
        var buf = new StringBuf();
        var walkers = createWalkers(config);
        for (element in blockElements) {
            for (walker in walkers)
                walker.walkBlockElement(element, Root);
            buf.add(Printer.print(element));
        }
        return Success(buf.toString());
    }

    public static function formatClassFields(classFields:Array<ClassField>, ?config:Config):Result<String> {
        var buf = new StringBuf();
        var walkers = createWalkers(config);
        for (field in classFields) {
            for (walker in walkers)
                walker.walkClassField(field, Root);
            buf.add(Printer.print(field));
        }
        return Success(buf.toString());
    }

    private static function createWalkers(config):Array<StackAwareWalker> {
        return [new Processor(config), new Indenter(config)];
    }

    public static function formatSource(source:String, entryPoint:EntryPoint = File, ?config:Config):Result<String> {
        var parsed = HxParser.parse(source, entryPoint);
        config = applyDefaultSettings(config);
        if (config.newlineCharacter == Auto) {
            config.newlineCharacter = if (source.has("\r\n")) CRLF else LF;
        }
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
        config = if (config == null) {} else Reflect.copy(config);

        if (config.baseConfig == null)
            config.baseConfig = Default;

        var defaults = config.baseConfig.get();
        StructDefaultsMacro.applyDefaults(config, defaults);
        return config;
    }
}