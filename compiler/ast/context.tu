use compiler.utils
use std

//compile phase
Context::getLocalVar(varname)
{
    var = GF().FindLocalVar(varname)
    if var != null return var

    var = GP().getGlobalVar("",varname)
    if var != null return var

    utils.debug(
        "variable:%s not define in local or params or global filename:%s"
        ,varname,GF().parser.filename
    )
    return null
}