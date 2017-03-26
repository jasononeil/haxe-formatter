package haxeFormatter.formatting;

import haxe.ds.ArraySort;
import haxeFormatter.Config.Modifier;
import hxParser.ParseTree.FieldModifier;

class ModifierSorter {
    public static function sort(modifiers:Array<FieldModifier>, order:Array<Modifier>) {
        inline function getRank(modifier:FieldModifier):Int {
            var rank = order.indexOf(modifier.getName().toLowerCase());
            return if (rank == -1) 100 else rank;
        }

        ArraySort.sort(modifiers, function(modifier1, modifier2) {
            return getRank(modifier1) - getRank(modifier2);
        });
    }
}