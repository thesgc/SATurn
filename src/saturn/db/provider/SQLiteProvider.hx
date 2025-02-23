/*
* SATURN (Sequence Analysis Tool - Ultima regula natura)
* Written in 2018 by David Damerell <david.damerell@sgc.ox.ac.uk>, Claire Strain-Damerell <claire.damerell@sgc.ox.ac.uk>, Brian Marsden <brian.marsden@sgc.ox.ac.uk>
*
* To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this
* software to the public domain worldwide. This software is distributed without any warranty. You should have received a
* copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
*/

package saturn.db.provider;

import saturn.db.provider.GenericRDBMSProvider;
import bindings.Sqlite3;

class SQLiteProvider extends GenericRDBMSProvider{

    public function new(models : Map<String,Map<String,Map<String,Dynamic>>>, config : Dynamic, autoClose : Bool){
        super(models, config, autoClose);
    }

    override public function getProviderType() : String{
        return 'SQLITE';
    }

    override public function getColumns(connection : Dynamic, schemaName : String, tableName : String, cb:String->Array<String>->Void) : Void{
        debug('Getting columns for ' + tableName);

        connection.serialize(function() {
            connection.all('PRAGMA table_info('+tableName+')',[],function(err,rows : Array<Dynamic>){
                if(err != null){
                    debug('Got pragma exception on  ' + tableName);
                    cb(err,null);
                }else{
                    var cols = new Array<String>();
                    for(row in rows){
                        cols.push(row.name);
                    }

                    cb(null, cols);
                }
            });
        });
    }

    override public function generateQualifiedName(schemaName : String, tableName : String) : String{
        return  tableName;
    }

    override public function _getConnection(cb : String->Connection->Void){
        try{
            var conn : Dynamic = new Sqlite3(config.file_name);
            debug('Got connection');

            conn.execute = conn.all;

            cb(null, conn);
        }catch(e : Dynamic){
            debug('Error' + e);

            cb(e,null);
        }
    }

    override public function limitAtEndPosition(){
        return true;
    }

    override public function generateLimitClause(limit){
        return ' limit ' + Std.int(limit);
    }
}