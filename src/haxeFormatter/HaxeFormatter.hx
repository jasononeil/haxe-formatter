package haxeFormatter;

import hxParser.JsonParser;
import hxParser.HxParser;
using Lambda;

class HaxeFormatter {
    public static function format(code:String):String {
        var parsed = HxParser.parse(code);
        var data:JNodeBase = null;
        switch (parsed) {
            case Success(d): data = d;
            case Failure(_): return null;
        }

        var tree:Tree = JsonParser.parse(data);
        var haxeBuf = new StringBuf();
        function loop(tree:Tree) {
            switch (tree.kind) {
                case Node(_, children): children.iter(loop);
                case Token(token, trivia):
                    if (trivia == null) haxeBuf.add(token)
                    else {
                        if (trivia.leading != null) trivia.leading.iter(loop);
                        if (!trivia.implicit && !trivia.inserted && token != "<eof>") haxeBuf.add(token);
                        if (trivia.trailing != null) trivia.trailing.iter(loop);
                    }
            }
        }
        loop(tree);
        return haxeBuf.toString();
    }
}