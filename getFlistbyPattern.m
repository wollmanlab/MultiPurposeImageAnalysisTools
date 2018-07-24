function flistDo = getFlistbyPattern(pattern, fpath)

    Temp = pattern;
    flist = dir(fpath);
    flist = {flist.name};
    ix1 = regexp(flist, Temp);
    ix=~cellfun('isempty',ix1) ;
    flistDo = flist(ix);
    %flistDo'
end