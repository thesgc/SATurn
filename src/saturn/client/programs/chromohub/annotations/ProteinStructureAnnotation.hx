package saturn.client.programs.chromohub.annotations;

import phylo.PhyloAnnotationManager;
import phylo.PhyloAnnotation;
import phylo.PhyloScreenData;
import phylo.PhyloAnnotation.HasAnnotationType;
import phylo.PhyloTreeNode;
import saturn.client.core.CommonCore;

class ProteinStructureAnnotation {
    public function new() {

    }

    static function hasStructure(target: String, data: Dynamic, selected:Int, annotList:Array<PhyloAnnotation>, item:String, cb : HasAnnotationType->Void){
        var r : HasAnnotationType = {hasAnnot: true, text:'',color:{color:'',used:false},defImage:100};

        if(data!=null){
            if(Reflect.hasField(data, 'sgc')){

                if(data.sgc==1){
                    r.color={color:'#2980d6',used:true};
                }else{
                    r.color={color:'#bf0000',used:true};
                }

                cb(r); return;
            }
        }

        cb(null);
    }

    static function divStructure(screenData: PhyloScreenData, x:String, y:String, tree_type:String, callBack : Dynamic->Void){
        if(screenData.divAccessed==false){
            screenData.divAccessed=true;

            if(screenData.targetClean.indexOf('/')!=-1){
                var auxArray=screenData.targetClean.split('');
                var j:Int;
                var nom='';
                for(j in 0...auxArray.length){
                    if(auxArray[j]!='/') nom+=auxArray[j];
                }
                screenData.targetClean=nom;
            }
            if(screenData.target.indexOf('/')!=-1){
                var auxArray=screenData.target.split('');
                var j:Int;
                var nom='';
                for(j in 0...auxArray.length){
                    if(auxArray[j]!='/') nom+=auxArray[j];
                }
                screenData.target=nom;
            }

            var name:String;
            if (screenData.target.indexOf('(')!=-1) name=screenData.targetClean;
            else if (screenData.target.indexOf('-')!=-1) name=screenData.targetClean;
            else name=screenData.target;
            trace('Family:');

            //var fam=screenData.family;
            var fam='';
            var prog = cast(WorkspaceApplication.getApplication().getActiveProgram(), ChromoHubViewer);
            if(prog.treeName!='') fam=prog.treeName;
            else{
                //the first family domain the target belong to, will be use as targetFamily. And it is stored in the leaf.targetFamily

                var leafaux:PhyloTreeNode;
                leafaux=prog.geneMap.get(screenData.targetClean);
                fam=leafaux.targetFamily;
            }

            var imgSrc='';
            var num='-1';
            var dom='';
            var al='structure_images/'+fam;

            var viewer = cast(WorkspaceApplication.getApplication().getActiveProgram(), ChromoHubViewer);
            var selectedAnnotations = viewer.annotationManager.getSelectedAnnotationOptions(screenData.annot);
            var cutoff = selectedAnnotations[0].cutoff;
            var cutoffParam = '';

            if(tree_type=='domain'){
                if (screenData.target.indexOf('(')!=-1 || screenData.target.indexOf('-')!=-1){
                    var auxArray=screenData.target.split('');
                    var j:Int;
                    for(j in 0...auxArray.length){
                        if(auxArray[j]=='(') num+='_'+auxArray[j+1];
                        if(auxArray[j]=='-') num='-'+auxArray[j+1];
                    }
                }
                imgSrc=al+'_DOMAIN/'+name+num+'_'+fam+'_DOMAIN';
                dom='_domain';
            } else{

                if(cutoff == '40%') {
                    cutoffParam = '_40';
                }
                if(cutoff == '95% or best') {
                    cutoffParam = '_best';
                }

                imgSrc = al+'/'+name+num+'_'+fam+cutoffParam;
                dom='';
            }

            var mapp='';

            CommonCore.getContent('/static/' +imgSrc+'.txt',function(filetext){
                mapp=filetext;
                //mapp = '<map name="st_' + screenData.target + '">'+ filetext + '</map>';

                var t = '<style type="text/css">
                        .divMainDiv7  { }
                        .divTitle{padding:5px; widht:100%!important; background-color:#dddee1; color:#6d6d6e!important; font-size:16px; margin-bottom:5px;}
                        .divContent{padding:5px;widht:100%!important;}
                        .divMainDiv7  a{ text-decoration:none!important;}
                        .divExtraInfo{padding:5px; widht:100%!important; font-size:10px; margin-top:5px;}

                        .structureResult{padding:3px 10px ;}
                        </style>
                        <div class="divMainDiv7 ">
                        <div class="divTitle">Structure Coverage ('+screenData.target+')</div>
                        <div class="divContent">
                        <img onload="app.getSingleAppContainer().annotWindowDoLayout()" src="http://apps.thesgc.org/resources/phylogenetic_trees/'+imgSrc+'.png" usemap="#st_'+name+num+'"><br>'+filetext+'

                        </div>
                        <div class="divExtraInfo">Click <a href="http://apps.thesgc.org/resources/phylogenetic_trees/structure_images.php?target='+screenData.targetClean+'&domain='+screenData.family+'&st_select=all&st_cutoff=high" target="_blank">here</a> to see all variants</div>
                        </div>
                    ';
                callBack(t);

            }, function(failmessage){
                WorkspaceApplication.getApplication().debug('Image map couldn\'t be accessed.');

                var t = '<style type="text/css">
                        .divMainDiv8  { }
                        .divTitle{padding:5px; widht:100%!important; background-color:#dddee1; color:#6d6d6e!important; font-size:16px; margin-bottom:5px;}
                        .divContent{padding:5px;widht:100%!important;}
                        .divMainDiv8  a{ text-decoration:none!important;}
                        .divExtraInfo{padding:5px; widht:100%!important; font-size:10px; margin-top:5px;}

                        .structureResult{padding:3px 10px ;}
                        </style>
                        <div class="divMainDiv8 ">
                        <div class="divTitle">Structure Coverage ('+screenData.target+')</div>
                        <div class="divContent">
                        <img onload="app.getSingleAppContainer().annotWindowDoLayout()" src="http://apps.thesgc.org/resources/phylogenetic_trees/'+imgSrc+'.png"><br>

                        </div>
                        <div class="divExtraInfo">Click <a href="http://apps.thesgc.org/resources/phylogenetic_trees/structure_images.php?target='+screenData.targetClean+'&domain='+screenData.family+'&st_select=all&st_cutoff=high" target="_blank">here</a> to see all variants</div>
                        </div>
                    ';
                callBack(t);
            });
        }
        else
            WorkspaceApplication.getApplication().debug("NOT access db");
    }

    static function structuresFunction (annotation:Int,form:Dynamic,tree_type:String, family:String,searchGenes:Array<Dynamic>,annotationManager:ChromoHubAnnotationManager, callback:Dynamic->String->Void){
        var aux:Dynamic;
        var cutoff:String;
        var option:String;
        var xray:String;

        if(form!=null){
            aux=form.form.findField('oplist');
            option=aux.lastValue.structure;

            aux=form.form.findField('cutoff');
            cutoff=aux.lastValue;

            aux=form.form.findField('xray');
            xray=aux.lastValue;
        }else{
            // it means the function is called from the annotations table, so we need to use the default values
            option='0';
            cutoff="95%";
            xray='false';
        }


        var r : HasAnnotationType = {hasAnnot: true, text:'',color:{color:'',used:true},defImage:100};

        var args = [{'treeType':tree_type,'familyTree':family, 'st_select':option, 'cutoff':cutoff, 'xray':xray, 'searchGenes':searchGenes}];
        annotationManager.setSelectedAnnotationOptions(annotation, args);

        WorkspaceApplication.getApplication().getProvider().getByNamedQuery('hookStructures', args, null, false,function(db_results, error){
            if(error == null) {
                if (db_results!=null){
                    annotationManager.activeAnnotation[annotation]=true;
                    if(annotationManager.treeName==''){
                        annotationManager.addAnnotDataGenes(db_results,annotation,function(){
                            callback(db_results,null);
                        });
                    }else{
                        annotationManager.addAnnotData(db_results,annotation,0,function(){
                            annotationManager.canvas.redraw();
                            callback(db_results,null);
                        });
                    }
                }
            }
            else {
                WorkspaceApplication.getApplication().debug(error);
                callback(null,error);
            }
        });
    }
}
