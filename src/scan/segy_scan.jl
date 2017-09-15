export segy_scan

"""
    segy_scan(dir::String, filt::String, keys::Array{String,1}, blocksize::Int; 
                           chunksize::Int = 1024,
                           pool::WorkerPool = WorkerPool(workers()),
                           verbosity::Int = 1)

    returns: SeisCon

Scan header fields `keys` of files in `dir` matching the filter `filt` in blocks
containing `blocksize` continguous traces. The scanning of files is distributed to workers
in `pool`, the default pool is all workers.

`chunksize` determines how many MB of data will be loaded into memory at a time.

`verbosity` set to 0 silences updates on the current file being scanned.

"""
function segy_scan(dir::String, filt::String, keys::Array{String,1}, blocksize::Int; 
                    chunksize::Int = 1024,
                    pool::WorkerPool = WorkerPool(workers()),
                    verbosity::Int = 1)
    
    endswith(dir, "/") ? nothing : dir *= "/"
    filenames = searchdir(dir, filt)
    files = map(x -> dir*x, filenames)
    files_sort = files[sortperm(filesize.(files), rev = true)]
    run_scan(f) = scan_file(f, keys, blocksize, chunksize=chunksize, verbosity=verbosity)
    s = pmap(pool, run_scan, files_sort)

    return merge_con(s)
end

function segy_scan(dirs::Array{String,1}, filt::String, keys::Array{String,1}, blocksize::Int; 
                    chunksize::Int = 1024,
                    pool::WorkerPool = WorkerPool(workers()),
                    verbosity::Int = 1)
    
    files = Array{String,1}()
    for dir in dirs 
        endswith(dir, "/") ? nothing : dir *= "/"
        filenames = searchdir(dir, filt)
        append!(files, map(x -> dir*x, filenames))
    end
    files_sort = files[sortperm(filesize.(files), rev = true)]
    run_scan(f) = scan_file(f, keys, blocksize, chunksize=chunksize, verbosity=verbosity)
    s = pmap(pool, run_scan, files_sort)
    
    return merge_con(s)
end

"""
    segy_scan(dir::String, filt::String, keys::Array{String,1})

If no `blocksize` is specified, the scanner automatically detects source locations and returns
blocks of continguous traces for each source location. 
"""
function segy_scan(dir::String, filt::String, keys::Array{String,1}; 
                    chunksize::Int = 1024,
                    pool::WorkerPool = WorkerPool(workers()),
                    verbosity::Int = 1)
    
    endswith(dir, "/") ? nothing : dir *= "/"
    filenames = searchdir(dir, filt)
    files = map(x -> dir*x, filenames)
    files_sort = files[sortperm(filesize.(files), rev = true)]
    run_scan(f) = scan_file(f, keys, chunksize=chunksize, verbosity=verbosity)
    s = pmap(run_scan, files_sort)
    
    return merge_con(s)
end

"""
    segy_scan(dir::Array{String,1}, filt::String, keys::Array{String,1})

Scans all files whose name contains `filt` in each directory of `dir`.
"""
function segy_scan(dirs::Array{String,1}, filt::String, keys::Array{String,1}; 
                    chunksize::Int = 1024,
                    pool::WorkerPool = WorkerPool(workers()),
                    verbosity::Int = 1)

    files = Array{String,1}()
    for dir in dirs 
        endswith(dir, "/") ? nothing : dir *= "/"
        filenames = searchdir(dir, filt)
        append!(files, map(x -> dir*x, filenames))
    end
    files_sort = files[sortperm(filesize.(files), rev = true)]
    run_scan(f) = scan_file(f, keys, chunksize=chunksize, verbosity=verbosity)
    s = pmap(pool, run_scan, files_sort)
    
    return merge_con(s)
end

searchdir(path,filt) = filter(x->contains(x,filt), readdir(path))
