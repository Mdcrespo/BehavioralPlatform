Notebooks to be run for classification training and prediction. Outputs are presented in Output folder

For Predictions and PredictionAsVideo, "test_result_dave_dir" determines which directory within output folder data is saved in.

Visualize_Augmentations - Allows a visual representation of the augmentations that take place during training (rotation, reflection, sharpness alteration)

Training - Trains and validates model for set number of epochs. Default 35 epochs. Outputs accuracy and loss plots for training and validation

Testing - Tests model on novel data - prints testing performance at bottom of terminal

Predictions - Predicts unlabeled data as OpenEye or OccludedEye. Set number of frames to be predicted by altering variable "numFrames". Outputs all predictions and class confidence as "predictions.csv" as well as individual frames in png format with predicted class

PredictionAsVideo - Takes individual frames and recombines into single .avi video file with predicted class in each frame