/*
* SATURN (Sequence Analysis Tool - Ultima regula natura)
* Written in 2018 by David Damerell <david.damerell@sgc.ox.ac.uk>, Claire Strain-Damerell <claire.damerell@sgc.ox.ac.uk>, Brian Marsden <brian.marsden@sgc.ox.ac.uk>
*
* To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this
* software to the public domain worldwide. This software is distributed without any warranty. You should have received a
* copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
*/

package saturn.server.plugins.socket;

import bindings.NodeFSExtra;
import bindings.NodeTemp;
import js.Node;
import saturn.app.SaturnServer;
import bindings.Ext.NodeSocket;

import com.dongxiguo.continuation.Continuation;
@:build(com.dongxiguo.continuation.Continuation.cpsByMeta(":cps"))
class PSIPREDPlugin extends QueuePlugin {
    var debug_psipred : Dynamic = Node.require('debug')('saturn:psipred');

    public function new(server : SaturnServer, config : Dynamic){
        super(server, config);
    }

    override public function processRequest(job, done, cb){
        Node.console.info('Running PSIPRED');
        runPSIPRED(job, done, cb);
    }

    @:cps public function runPSIPRED(job : Dynamic, done) : Void{
        var jobId = getJobId(job);

        debug_psipred('Creating temporary file');

        var err, info = @await NodeTemp.open('psiPredQuery');
        if(err != null){
            handleError(job,err, done); return;
        }

        debug_psipred('Writing FASTA');

        var buffer : NodeBuffer = new NodeBuffer( job.data.fasta );

        var err = @await Node.fs.writeFile(info.path,buffer);
        if(err != null){
            handleError(job,err, done); return;
        }

        var inputFileName = info.path;
        var outputFileName =  inputFileName+'.horiz';

        var cmd = './runpsipred_single';
        var dir = 'bin/deployed_bin/psipred/unix';
        var full_command = dir + '/runpsipred_single';

        if(Node.os.platform() == 'win32'){
            cmd = 'runpsipred_single.bat';
            dir = 'bin\\deployed_bin\\psipred\\win\\';

            full_command = dir +  cmd;
        }

        var fs_lib = Node.require('fs');

        fs_lib.access(full_command,fs_lib.constants.F_OK, function(err){
            if(err != null){
                handleError(job,'PSIPred executable not found in ' + full_command +
                                    '<br/><br/>Follow the instructions <a target="_blank" href="/static/manual/index.html#PSIPred%20Installation">here</a> to install PSIPRED', done); return;
            }

            debug_psipred('Running PSIPred');

            var proc : NodeChildProcess = Node.child_process.spawn(cmd,[inputFileName],{cwd:dir});

            proc.stderr.on('data', function(error){
                Node.console.log(error.toString());
            });

            proc.stdout.on('data', function(error){
                Node.console.log(error.toString());
            });

            proc.on('close', function(code){
                if(code == "0"){
                    debug_psipred('Preparing files for client');

                    var serveFileName : String = saturn.getRelativePublicOuputFolder() + '/' + this.saturn.pathLib.basename(outputFileName);
                    var reportServeFileName : String = saturn.getRelativePublicOuputURL() + '/' + this.saturn.pathLib.basename(outputFileName);

                    NodeFSExtra.copy(outputFileName, serveFileName, function(err){
                        if(err != null){
                            handleError(job,'An error has occurred making the results file available', done); return;
                        }

                        Node.fs.readFile(serveFileName, null, function(err_read, data){
                            if(err_read!= null){
                                handleError(job,'An error has occurred opening the results file', done); return;
                            }

                            NodeTemp.open('psiPredQuery', function(err_temp, info){
                                if(err_temp != null){
                                    handleError(job,'An error has occurred generating a temporary file for results', done); return;
                                }

                                var buffer : NodeBuffer = new NodeBuffer( '<html><body><pre>'+data+'</pre></body></html>' );

                                Node.fs.writeFile(info.path,buffer, function(err_write){
                                    if(err_write != null){
                                        handleError(job,'An error has occurred writing the results file', done); return;
                                    }

                                    var htmlResultsFile : String = saturn.getRelativePublicOuputFolder() + '/' + this.saturn.pathLib.basename(info.path) + '.html';
                                    var reportHtmlResultsFile : String = saturn.getRelativePublicOuputURL() + '/' + this.saturn.pathLib.basename(info.path) + '.html' ;

                                    NodeFSExtra.copy(info.path, htmlResultsFile, function(err){
                                        debug_psipred('Sending response');

                                        sendJson(job, {htmlPsiPredReport:reportHtmlResultsFile,rawHoriReport:reportServeFileName}, done);
                                    });
                                });
                            });

                        });

                    });


                }else{
                    handleError(job,'PSIPRED has returned a non-zero exit status: ' + code, done); return;
                }
            });
        });

    }
}