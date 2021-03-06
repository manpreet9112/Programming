
clc
clear


load input.mat



function Stiffness_matrix =stif(Stiffness_storey,Number_of_storeys)
#function for calculating Stiffness_matrix
#outer for loop
                #loop variable intialization
		for  storey_i = 1:Number_of_storeys
                       #assign first value of stiffness_storey to stiffness_matrix a11 position
  			Stiffness_matrix(storey_i, storey_i) = ...
    			Stiffness_storey(storey_i);
  			if (storey_i < Number_of_storeys )
                        #conditional statement.
    				Stiffness_matrix(storey_i, storey_i) = ...
     				Stiffness_matrix(storey_i, storey_i) + ...
      				Stiffness_storey(storey_i + 1);
    				Stiffness_matrix(storey_i, storey_i + 1) = ...
     				- Stiffness_storey(storey_i + 1);
    				Stiffness_matrix(storey_i + 1, storey_i) = ...
      				Stiffness_matrix(storey_i, storey_i + 1);
   			endif
	 	end
end


function Level_floor =levelf(Height_storey)
        Number_of_storeys=4;
	for storey_i = 1 :Number_of_storeys
  		Level_floor(storey_i, 1) = ...
    		Height_storey(storey_i,1);
  		if (storey_i>1)
     			Level_floor(storey_i, 1) = ...
       			Level_floor(storey_i, 1) + ...
     			Level_floor(storey_i - 1, 1);
 		 endif
	end
end

function [Time_period, Frequency, Time_periods]= eigenomega(Stiffness_matrix, Mass,Number_of_storeys)
[Eigen_vector, Omega_square] = eig(Stiffness_matrix, Mass);
Omega = sqrt(Omega_square);
	for storey_i = 1 : Number_of_storeys
	  Time_period(storey_i, storey_i) = 2 * pi() ...
	    / sqrt(Omega_square(storey_i, storey_i)); 
	end
	for storey_i = 1 : Number_of_storeys
	  Frequency(storey_i,1) = Omega(storey_i, storey_i);
	end
	for storey_i = 1 : Number_of_storeys
	  Time_periods(storey_i,1) = Time_period(storey_i, storey_i);
	end
end

function [Modal_participation_factor,Modal_mass,Modal_contribution,ModesContributionX,Number_of_modes_to_be_considered]=modal(Mass, Eigen_vector,Number_of_storeys,Modes_considered)
sum_modal_mass = 0;
	for index_k = 1 : Number_of_storeys
  		sum_W_Phi = 0;
  		sum_W_Phi2 = 0;
  			for index_i = 1 : Number_of_storeys
    				sum_W_Phi = sum_W_Phi + Mass(index_i, index_i) * ...
      				Eigen_vector(index_i, index_k);
    				sum_W_Phi2 = sum_W_Phi2 + Mass(index_i, index_i) * ...
      				Eigen_vector(index_i, index_k)^2;
  			end
Modal_participation_factor(index_k,1) = sum_W_Phi / sum_W_Phi2;
Modal_mass(index_k,1) = (sum_W_Phi^2) / (sum_W_Phi2);
sum_modal_mass = sum_modal_mass + Modal_mass(index_k,1);  
end

Modal_contribution = 100 / sum_modal_mass * Modal_mass;

ModesContributionX = 0;
Number_of_modes_to_be_considered = 0;

	for Number_of_modes_to_be_considered = 1:Number_of_storeys
  		ModesContributionX = ModesContributionX + ...
   		Modal_contribution(Number_of_modes_to_be_considered); 
 		  if (ModesContributionX > 90)
   			 break;
  		endif
	end


if (Modes_considered == 0)
  Modes_considered = Number_of_modes_to_be_considered;
endif

end


function [Sa_by_g,A_h,Design_lateral_force,Peak_shear_force]=Peak_shear(Time_periods,Zone_factor,Importance_factor,
Mass,Eigen_vector,Gravity_acceleration,Response_reduction_factor,Modal_participation_factor,Type_of_soil,Number_of_storeys )
	for index_time = 1:Number_of_storeys
  		Sa_by_g(index_time,1) = funSaog(Type_of_soil , Time_periods(index_time,1));
  		A_h(index_time,1) = Zone_factor / 2 * Importance_factor / ...
   		 Response_reduction_factor * Sa_by_g(index_time,1);
	end  

	for index_i = 1:Number_of_storeys
  		Design_lateral_force(:,index_i) = Mass * Eigen_vector(:,index_i) * A_h(index_i) * ...
 		Modal_participation_factor(index_i) * Gravity_acceleration;
	end

Peak_shear_force = zeros(Number_of_storeys, Number_of_storeys,'double');
	for index_j = 1:Number_of_storeys
  		for index_i = 1:Number_of_storeys
      			for index_k = 1:Number_of_storeys - index_i +1
     			% index_m = index_k + index_i -1;
      			Peak_shear_force(index_i,index_j) = ...
       			 Design_lateral_force(index_k + index_i -1,index_j) + ...
       			 Peak_shear_force(index_i,index_j);
        		%index_i
       			 %index_j
        		%index_k
   			 end    
  		end  
	end

end

function Storey_shear_force= storey_shear(Peak_shear_force,Modes_considered,Number_of_storeys)	Storey_shear_force = zeros(Number_of_storeys, 3);
	for index_i = 1:Number_of_storeys
  		for index_j = 1:Modes_considered
   	 		Storey_shear_force(index_i,1) = Storey_shear_force(index_i,1) + ...
   	   		abs(Peak_shear_force(index_i,index_j));
   	 		Storey_shear_force(index_i,2) = Storey_shear_force(index_i,2) + ...
   	   		Peak_shear_force(index_i,index_j)^2;
  		end
   	Storey_shear_force(index_i,2) = sqrt(Storey_shear_force(index_i,2));
	end
end

function [Eigen_vector, level_floor]=plott(Eigen_vector,level_floor,Number_of_storeys)
	plotHangle = figure('visible', 'off')
        plot([0; Eigen_vector(:,1)], [0; level_floor],'-ro')
	hold on
	plot([0; Eigen_vector(:,2)], [0; level_floor],'-go')
	plot([0; Eigen_vector(:,3)], [0; level_floor],'-bo')
	plot([0; Eigen_vector(:,4)], [0; level_floor],'-mo')
	plot([0 0], [0 level_floor(Number_of_storeys)],'-k')
	hold off
end




Type_of_soil ='';

for i = 1:Soil_type
 Type_of_soil = strcat(Type_of_soil, 'I');
end

%% Function to write Matrix

%t1 = 0; t2 = 0; t3 = 0; t4 = 0; 
%eq3num = 0;


function sag = funSaog(soilType, timePrd)
    t2=0.10;t1 = 0;t3 = 0; t4 = 0; 
eq3num = 0;
    switch soilType
    case 'I' 
      t3 = 0.40; eq3num = 1.0;
    case 'II'
      t3 = 0.55; eq3num = 1.36;
    case 'III'
      t3 = 0.67; eq3num = 1.67;
    otherwise
      warning('Unexpected soil type');
  end
  if (timePrd < t2)
    sag = 1. + 15 * timePrd;  
  elseif (timePrd > t3)
    sag = eq3num / timePrd; 
  else
    sag = 2.5;
  end
end

function matrixTeX(A, fmt, align)
  disp(['\section{',strrep(inputname(1),'_',' '),'}'])
  [m,n] = size(A);
  if isvector(A)
    myMatrix = 'Bmatrix';
  else
    myMatrix = 'bmatrix';
  end
  if(nargin < 2)
    %
    % Is the matrix full of integers?
    % If so, then use integer output
    %
    if( norm(A-floor(A)) < eps )
      intA = 1;
      fmt  = '%d';
    else
      intA = 0;
      fmt  = '%8.4f';
    end
  end
  fmtstring1 = [' ',fmt,' & '];
  fmtstring2 = [' ',fmt,' \\\\ \n'];
  if(nargin < 3)
    printf('\\[\n\\begin{%s}\n',myMatrix);
  else
    printf('\\[\n\\begin{%s*}[%s]\n',myMatrix,align);
  endif  
  for i = 1:m
    for j = 1:n-1
       printf(fmtstring1,A(i,j));
    end
    printf(fmtstring2, A(i,n));
  end
  if(nargin < 3)
    printf('\\end{%s}\n\\]\n',myMatrix);
  else
    printf('\\end{%s*}\n\\]\n',myMatrix);
  endif  
end


%function calling and output
Stiffness_matrix=stif(Stiffness_storey,Number_of_storeys); 
disp(sprintf ( 'Stiffness_matrix:\t'))
disp(Stiffness_matrix);
disp(sprintf ( 'Level_floor: \t'))
level_floor=levelf(Height_storey);
disp(level_floor);
[Time_period, Frequency, Time_periods]= eigenomega(Stiffness_matrix, Mass,Number_of_storeys)
disp(sprintf ('Time_periods :\t'))
disp(Time_periods);
disp(sprintf ('Frequency :\t'))
disp(Frequency);
[Eigen_vector, Omega_square] = eig(Stiffness_matrix, Mass);
disp(sprintf ('Eigen_vector:\t'))
disp(Eigen_vector);
disp(Omega_square);
[Modal_participation_factor,Modal_mass,Modal_contribution,ModesContributionX,Number_of_modes_to_be_considered]=modal(Mass, Eigen_vector,Number_of_storeys,Modes_considered)
disp(sprintf ('Mass:\t'));
disp(Mass);
disp(sprintf ('Modal_mass:\t'))
disp(Modal_mass);
disp(sprintf ('Modal_participation_factor:\t'))
disp(Modal_participation_factor);
disp(sprintf ('Modal_contribution:\t'))
disp(Modal_contribution);
[Sa_by_g,A_h,Design_lateral_force,Peak_shear_force]=Peak_shear(Time_periods,Zone_factor,Importance_factor,Mass,Eigen_vector,Gravity_acceleration,Response_reduction_factor,Modal_participation_factor,Type_of_soil,Number_of_storeys)
disp(sprintf ('Sa_by_g:\t'))
disp(Sa_by_g);
disp(sprintf ('Design_lateral_force:\t'))
disp(Design_lateral_force);
Storey_shear_force= storey_shear(Peak_shear_force,Modes_considered,Number_of_storeys)
disp('Storey_shear_force')
disp(Storey_shear_force);
[Eigen_vector, level_floor]=plott(Eigen_vector,level_floor,Number_of_storeys)



%output of functions in latex form
matrixTeX(Stiffness_matrix,'%10.4e','r')
matrixTeX(level_floor,'%10.4e','r')
matrixTeX(Time_periods,'%10.4e','r')
matrixTeX(Frequency,'%10.4e','r')
matrixTeX(Eigen_vector,'%10.4e','r')
matrixTeX(Omega_square,'%10.4e','r')
matrixTeX(Mass,'%10.4e','r')
matrixTeX(Modal_mass,'%10.4e','r')
matrixTeX(Modal_participation_factor,'%10.4e','r')
disp(' ')
disp(['g = ', num2str(Gravity_acceleration)])

matrixTeX(Modal_contribution,'%10.4e','r')
disp(['Modal Contribution of ', num2str(ModesContributionX), ' \% for ', ...
  num2str(Number_of_modes_to_be_considered), ' number of modes '])
disp(['Modes Considered ', num2str(Modes_considered)])
	
matrixTeX(Sa_by_g,'%10.4e','r')
matrixTeX(A_h,'%10.4e','r')
matrixTeX(Design_lateral_force,'%10.4e','r')
matrixTeX(Peak_shear_force,'%10.4e','r')
matrixTeX(Storey_shear_force,'%10.4e','r')

%% Plot mode shapes




% saveas(plotHangle, 'ModeShape.eps','eps')
%print (plotHangle, '-color',  'ModeShape.eps')
%saveas(plotHangle, 'ModeShape.png','png')
%saveas(plotHangle, 'ModeShape.pdf')

% End of file
