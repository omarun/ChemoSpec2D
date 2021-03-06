#'
#' Import Data into a Spectra2D Object
#'
#' This function imports data into a \code{\link{Spectra2D}} object.  It uses
#' \code{\link[utils]{read.table}} to read files so it is
#' very flexible in regard to file formatting.  \pkg{Be sure to see the \ldots 
#' argument below for important details you need to provide.}
#'
#' \code{files2Spectra2DObject} acts on all files in the current working
#' directory with the specified \code{fileExt} so there should be no
#' extra files of that type.
#'
#' @param gr.crit Group Criteria.  A vector of character strings which will be
#' searched for among the file/sample names in order to assign an individual
#' spectrum to group membership. This is done using grep, so characters
#' like "." (period/dot) do not have their literal meaning (see below).
#' Warnings are issued if there are file/sample
#' names that don't match entries in \code{gr.crit} or there are entries in
#' \code{gr.crit} that don't match any file names.
#' 
#' @param gr.cols A character vector, giving one color per group.
#' 
#' @param x.unit A character string giving the units for the F2 dimension
#' (frequency or wavelength corresponding to the x dimension).
#' 
#' @param y.unit A character string giving the units for the F1 dimension
#' (frequency or wavelength corresponding to the y dimension).
#' 
#' @param z.unit A character string giving the units of the z-axis (some sort
#' of intensity).
#' 
#' @param descrip A character string describing the data set.
#' 
#' @param fmt A character string giving the format of the data. Consult
#' \code{\link{import2Dspectra}} for options.
#'
#' @param nF2 Integer giving the number of data points in the F2 (x) dimension.
#'
#' @param fileExt A character string giving the extension of the files to be
#' processed. \code{regex} strings can be used.  For instance, the default
#' finds files with either \code{".csv"} or \code{".CSV"} as the extension.
#' Matching is done via a grep process, which is greedy.
#' 
#' @param out.file A file name.  The
#' completed object of S3 class \code{\link{Spectra2D}} will be written to this
#' file.
#' 
#' @param debug Logical.
#' Set to \code{TRUE} for troubleshooting when an error
#' is thrown during import.
#' 
#' @param ...  Arguments to be passed to \code{\link[utils]{read.table}}.  \pkg{You
#' MUST supply values for \code{sep}, \code{dec} and \code{header} consistent
#' with your file structure, unless they are the same as the defaults for
#' \code{\link[utils]{read.table}}}.
#' 
#' @return A object of class \code{\link{Spectra2D}}.  An \emph{unnamed} object
#' of S3 class \code{\link{Spectra2D}} is also written to \code{out.file}.  To
#' read it back into the workspace, use \code{new.name <- loadObject(out.file)}
#' (\code{loadObject} is package \pkg{R.utils}).
#' 
#' @section gr.crit and Sample Name Gotchas:
#'
#' The matching of \code{gr.crit} against the sample file names
#' (in \code{files2SpectraObject}) or column headers/sample names
#' (in code{matrix2SpectraObject}) is done one at
#' a time, in order, using grep.  While powerful, this has the potential to lead
#' to some "gotchas" in certain cases, noted below.  
#'
#' Your file system may allow file/sample names which \code{R} will not like, and will
#' cause confusing behavior.  File/sample names become variables in \code{ChemoSpec},
#' and \code{R}
#' does not like things like "-" (minus sign or hyphen) in file/sample names.  A hyphen
#' is converted to a period (".") if found, which is fine for a variable name.
#' However, a period in \code{gr.crit} is interpreted from the grep point of view,
#' namely a period matches any single character.  At this point, things may behave
#' very differently than one might hope.  See \code{\link{make.names}} for allowed
#' characters in \code{R} variables and make sure your file/sample names comply.
#'
#' The entries in \code{gr.crit} must be
#' mutually exclusive.  For example, if you have files with names like
#' "Control_1" and "Sample_1" and use \code{gr.crit = c("Control", "Sample")}
#' groups will be assigned as you would expect.  But, if you have file names
#' like "Control_1_Shade" and "Sample_1_Sun" you can't use \code{gr.crit =
#' c("Control", "Sample", "Sun", "Shade")} because each criteria is grepped in
#' order, and the "Sun/Shade" phrases, being last, will form the basis for your
#' groups.  Because this is a grep process, you can get around this by using
#' regular expressions in your \code{gr.crit} argument to specify the desired
#' groups in a mutually exclusive manner.  In this second example, you could
#' use \code{gr.crit = c("Control(.*)Sun"}, \code{"Control(.*)Shade"}, \code{"Sample(.*)Sun"},
#' \code{"Sample(.*)Shade")} to have your groups assigned based upon both phrases in
#' the file names.
#'
#' To summarize, \code{gr.crit} is used as a grep pattern, and the file/sample names
#' are the target.  Make sure your file/sample names comply with \code{\link{make.names}}.
#'
#' Finally, samples whose names are not matched using \code{gr.crit} are still
#' incorporated into the \code{\link{Spectra2D}} object, but they are not
#' assigned a group. Therefore they don't plot, but they do take up space in a
#' plot!  A warning is issued in these cases, since one wouldn't normally want
#' a spectrum to be orphaned this way.
#'
#' All these problems can generally be identified by running \code{\link[ChemoSpecUtils]{sumSpectra}}
#' once the data is imported.
#'
#' @section Advanced Tricks:
#' While argument \code{fileExt} appears to be a file extension (from its
#' name and the description elsewhere), it's actually just a grep pattern that you can apply
#' to any part of the file name if you know how to contruct the proper pattern.
#'
#' @author Bryan A. Hanson, DePauw University.
#' 
#' @keywords import
#' 
#' @export files2Spectra2DObject
#'
#' @importFrom utils read.table
#' @importFrom tools file_path_sans_ext
#' @importFrom ChemoSpecUtils .groupNcolor
#'

files2Spectra2DObject <- function(gr.crit = NULL, gr.cols = "auto", 
	fmt = NULL, nF2 = NULL, 
	x.unit = "no frequency unit provided",
	y.unit = "no frequency unit provided",
	z.unit = "no intensity unit provided",
	descrip = "no description provided",
	fileExt = "\\.(csv|CSV)$",
	out.file = "mydata", debug = FALSE, ...) {
		
	if (!requireNamespace("R.utils", quietly = TRUE)) {
		stop("You need to install package R.utils to use this function")
		}
	
	if (is.null(gr.crit)) stop("No group criteria provided to encode data")
	if (is.null(nF2)) stop("You must provide nF2")
	if (is.null(fmt)) stop("You must provide fmt")

	out <- tryCatch(
	{

	# First set up some common stuff
	
	files <- list.files(pattern = fileExt)
	files.noext <- tools::file_path_sans_ext(files)
	ns <- length(files)

	spectra <- list()
	spectra$F2 <- NA_real_
	spectra$F1 <- NA_real_
	spectra$data <- vector("list", ns)
	spectra$names <- files.noext
	names(spectra$data) <- files.noext
	spectra$groups <- NA_character_
	spectra$units <- c(x.unit, y.unit, z.unit)
	spectra$desc <- descrip
	class(spectra) <- "Spectra2D"
	
	# Loop over all files

	if (debug) message("\nfiles2Spectra2DObject will now import your files")
	
	for (i in 1:ns) {
		if (debug) cat("Importing file: ", files[i], "\n")
		
		tmp <- import2Dspectra(files[i], fmt = fmt, nF2 = nF2, ...)
		spectra$data[[i]] <- tmp[["M"]]
		dimnames(spectra$data[[i]]) <- NULL # clean up to plain matrix
		if (i == 1L) {
			spectra$F2 <- tmp[["F2"]]
			spectra$F1 <- tmp[["F1"]]	
			}
			
		}
	
	# Assign groups & colors

	spectra <- .groupNcolor(spectra, gr.crit, gr.cols, mode = "2D")
	
	# Wrap up
	
	chkSpectra(spectra)
	
	datafile <- paste(out.file, ".RData", sep = "")
	R.utils::saveObject(spectra, file = datafile)
	return(spectra)
	},
	
	error = function(cond) {
		errmess <- "There was a problem importing your files!\n\nAre you importing csv or similar files? Did you get a message such as 'undefined columns selected'? You probably need to specify sep, header and dec values. Please read ?files2Spectra2DObject for details.\n\nFor any trouble importing files set debug = TRUE.\n"
		message("\nError message from R: ", cond$message, "\n")
		message(errmess)
		return(NA)
		}
	
	) # end of tryCatch
	
	return(out)
	}

