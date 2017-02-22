package haxeFormatter;

import hxParser.JsonParser;
using Lambda;

class Printer {
    public static function print(tree:Tree):String {
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