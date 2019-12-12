function R_out = calculateOutputSpatialReferencing(R_A,tform)
% Applies geometric transform to input spatially referenced grid to figure
% out the resolution and world limits after application of the forward
% transformation.
R_out = images.spatialref.internal.applyGeometricTransformToSpatialRef(R_A,tform);
end