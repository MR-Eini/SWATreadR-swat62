\name{swat_cio_set}
\alias{swat_cio_set}
\title{Update entries in a named file.cio section}
\usage{swat_cio_set(lines, section, positions, values)}
\arguments{
\item{lines}{Character vector containing file.cio.}
\item{section}{Section label, such as lum or climate.}
\item{positions}{Integer entry positions after the section label.}
\item{values}{One character replacement token per position.}
}
\value{Updated lines retaining other entries and sections.}
\description{Find the section by label, validate entry positions, and replace only the specified entries. This function does not migrate input schemas.}
