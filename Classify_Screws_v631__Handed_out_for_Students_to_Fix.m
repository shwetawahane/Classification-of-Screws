function Classify_Screws_v631__Handed_out_for_Students_to_Fix( )
%  This tests the use of the DecisionTree Classifiers to classify different screw types.
%
%  A decision tree will work, sorta, but there are better classifiers available.
%
%  "doc Classification Trees" for more information...
%
%  '21-Jul-2020'    Thomas B. Kinsman
%

warning('THIS CODE DOES NOT WORK.  YOU HAVE TO GET IT WORKING. ');
error('PLEASE DO NOT BE SO NAIVE AS TO THINK I AM GIVING YOU THE ANSWER!! ');

FS      = 28;
training_dir    = 'InputDirectoryForTrainingImages';
testing_dir     = 'InputDirectoryForTestingImages';         % This might not be incorporated yet.
nm_in           = 'im_type_*.jpg';                          % Training images all have the type in them... 
nm_mix          = 'im*mix*.jpg';                            % Testing images all have the word 'mix' in them... 
file_name_in           = [ training_dir filesep() nm_in ];

    initialize_the_feat_table     = true;
    classes                       = 'ABC';
    for class_number = 1:length(classes)
        
        this_cls_letter = classes(class_number);
        file_pattrn     = sprintf('%s%cim_type_%c*.jpg', training_dir, filesep(), this_cls_letter );
        training_files  = dir( file_pattrn );

        for idx = 1 : length( training_files )
            file_name_in = sprintf('%s%c%s', training_dir, filesep(), training_files(idx).name );
            fprintf('%s\n', file_name_in );
            
            feats   = get_features_v22( file_name_in );
            n_new   = size( feats, 1 );

            if ( initialize_the_feat_table == true )
                initialize_the_feat_table           = false;

                collected_feats                     = feats;
                class_list(1:n_new)                 = class_number;
            else
                % Append to the feature table.
                collected_feats(end+1:end+n_new,:)  = feats;
                class_list(end+1:end+n_new)         = class_number;
            end
        end
    end

    % Now, build a classifier, based on the collected data:
    tree_classifier = fitcdectree( ... ) or fitcsvm, or something like that ... 
                      you will need to look up the correct routine and syntax.
                      use fitc[TAB] to get a list of possible classifiers.
    
    %
    %  Test the classifier on the TRAINING DATA.  
    %  This might not be perfect.
    %
    %  setup and fill in a confusion_matrix
    %
    confusion_matrix = zeros(length(classes));
    for instance_id = 1 : size( collected_feats, 1 )

        true_cls = class_list( instance_id );
        pred_cls = tree_classifier.predict( collected_feats(instance_id,:) );

        confusion_matrix( pred_cls, true_cls ) = confusion_matrix( pred_cls, true_cls ) + 1;
    end
    
    % This is Dr. Kinsman's printing routine, I just use this for verification.
    % You might need your own.
    print_mat( confusion_matrix, 1, 'confusion_matrix_on_training_data', 0 );
    fprintf('\n\n');

    %
    %  Lead each mixture of screws, and classify the screws in them using the trained classifier...
    %
    %  All of the "mixed up" images have the word "mix in them"... 
    file_pattrn     = sprintf('%s%cim_mix_*.jpg', training_dir, filesep() );
    training_files  = dir( file_pattrn );

    % Print the header for the output:
    fprintf('%-50s,  ', 'File Name:' );
    for cls_idx = 0 : 3
        fprintf('%2d,  ', cls_idx);
    end
    fprintf('DIRT or something else ... \n');

    for idx = 1 : length( training_files )
        
        file_name_in    = sprintf('%s%c%s', training_dir, filesep(), training_files(idx).name );

        % Get a matrix of all possible feature sets:
        feat_sets       = get_features( file_name_in );

        % Classify each and every row of the feature matrix:
        pred_cls        = tree_classifier.predict( feat_sets );
        
        % Print the classifications for this image:
        fprintf('%-50s,  ', file_name_in );
        
        % Remember, these indices might be wrong... 
        for cls_idx = 1 : 4
            num_of_this_class = sum( pred_cls == cls_idx );
            fprintf('%2d,  ', num_of_this_class );
        end
        fprintf('\n');
    end
    
    warning('The entire end of this routine is missing.');
    warning('You have work to do.');
    warning('Given the input region, color it correctly.');
    
end



function feature_mat = get_features( fn_in )
% This encapsulates the part of the imaging chain which extracts screws from the image, 
% and finds their features.
%
% Noise cleaning, background removal, ...
%
FWIB            = 0.94;                %  FRACTION_OF IMAGE WHICH_IS_BACKGROUND
                                       %  I set this empirically, it might be wrong.
DEBUGGING_ON    = false;
FS      = 28;

    im      = imread( fn_in );
    im_gry  = rgb2gray( im );           % IMPORTANT this is a uint8 image.
                                        % Values are in the range [0 to 255].

    if ( DEBUGGING_ON )
        zoom_figure( [1200 900] );
        imagesc( im );
        colormap(gray(256));
        axis image;
    end

    %
    %   Find a good cut-off point, say the 94% point:
    %
    hst         = imhist( im_gry, 256 );
    cumhst      = cumsum( hst );
    frchst      = cumhst(:) / cumhst(end) ;
    hist_index  = find( frchst >= FWIB, 1, 'First' );

    threshold   = hist_index+1;

    im_foreground   = im_gry > threshold; 

    if ( DEBUGGING_ON )
        zoom_figure([1200 900]);
        imagesc( im_foreground );
        colormap(gray(256));
        axis image;
    end

    % This was determined empirically for a few images:
    %
    %
    % You need to do some noise cleaning on the image im_foreground,
    % and convert it into a binary image called im_cleaned.
    
    im_cleaned  = some noise cleaning of im_foreground

    if ( DEBUGGING_ON )
        zoom_figure([1200 700]);
        imagesc( im_cleaned );
        axis image;
    end

    feature_tbl = regionprops( 'table', im_cleaned,  ... 
        % pick some features to classify the screws with here ...
        % 'BoundingBox', 'Center of Mass', etc...    
    
    % Explicitly toss out very small particles:
    b_too_small                     = feature_tbl.Area <= 100;   % 100 = 10^2 
    feature_tbl(b_too_small,:)      = [];
    
    % CAUTION -- that heuristic parameter is resolution dependent.
    % A different camera will need a different parameter value.

    if ( DEBUGGING_ON )
        % Bunch of stuff deleted here... 
    end
    
    
    % 
    % Convert table to a matrix of features... 
    %
    for row = 1 : size( feature_tbl, 1 )
        feature_mat(row,1) = feature_tbl{row,1};
        feature_mat(row,2) = feature_tbl{row,2};
        feature_mat(row,3) = feature_tbl{row,3};
        feature_mat(row,4) = feature_tbl{row,4};
        feature_mat(row,5) = feature_tbl{row,5};
    end

end

