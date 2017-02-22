package util;

class Extensions {
    public static function has(s:String, substring:String):Bool {
        return s != null && s.indexOf(substring) != -1;
    }
}