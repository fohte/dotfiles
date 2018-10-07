#!/usr/bin/env perl

$latex = 'platex -halt-on-error';
$bibtex = 'pbibtex';
$dvipdf = 'dvipdfmx %O -o %D %S';
$max_repeat = 5;
$pdf_mode = 3;
$pdf_previewer = 'open -a Skim %S';
