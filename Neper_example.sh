#!/bin/bash

NEPER="neper --rcfile none"

#creating 30 grains with euler angles
$NEPER -T -n 30 -morpho gg -ori random -oriformat plain -oridescriptor e -o gene_mult_3

#create abaqus input file with hexagonal elements and continuous grain boundaries
$NEPER -M gene_mult_3.tess -statelset vol -rcl 1 -elttype hex -order 1 -interface continuous -format inp -o abq_input

exit 0


