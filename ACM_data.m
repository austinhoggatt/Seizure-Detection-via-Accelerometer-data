%   Date:        7/26/102
%   Programmer:  Austin L. Hoggatt
%   Description: Original Code 
%   
%   This program's purpose is to execute the following set of procedures:
%   (1) Load ACM data from user prompted excel file
%   (2) Standardize raw ACM data and Seizure Model
%   (3) Plot raw ACM data and Seizure Model
%   (4) Filter raw ACM data
%   (5) Align filtered ACM data with Seizure Model
%   (6) Compute absolute error of ACM impulse to Seizure Model

%------------------------------------------------------------------------%

% (1) Load ACM data from excel spread sheet:

%   1.1 
%   Prompt user to enter the data file name and columns used
data_file = input('Enter file name: ','s');
time_column = input('In which column number is the time data? ');
ACM_column = input('In which column number is the ACM data? ');
data = xlsread(data_file);

%   1.2 
%   Truncate data vectors to eliminate NaN's by creating an array 
%   that contains 1's where the elements of the vectors are 
%   NaN's and 0's where they are not
non_numbers = isnan(data);
for i = 1:length(data)
    if non_numbers(i) == 0
        T(i) = data(i,time_column);
        Acc_x(i) = data(i,ACM_column);
    else
        break
    end
end
t = transpose(T);
acc_x = transpose(Acc_x);
clear T Acc_x

%   1.3 
%   Seizure Model Equation:
t1 = t;
K = 42.6;
tau = 0.04;
A = 1.045;
B = 1.023;
x = K*(t1.*exp(-t1/tau)-t1/A.* exp(-t1/(B*tau)));

%------------------------------------------------------------------------%

% (2) Standardization of raw ACM data and Seizure Model
x_stand = standard(acc_x);
x_stand2 = standard(x);

%------------------------------------------------------------------------%

% (3) Plot raw ACM data and standard seizure model:
figure(1)
plot(t,acc_x)
title('Raw ACM data')
xlabel('Time (seconds)')
ylabel('Amplitude')

figure (2)
plot(t1,x_stand2,'r')
xlim([0 1])
title('Standardized seizure model')
xlabel('Time (seconds)')
ylabel('Amplitude')
    
figure(3)
scatter(t,x_stand,'filled')
hold on
plot(t1,x_stand2,'r')
hold on
plot(t,x_stand,'b')
title('Standardized ACM data vs. Standardized Seizure Model')
xlabel('Time (seconds)')
ylabel('Amplitude')

halted = input('Press Enter to continue');
%------------------------------------------------------------------------%

%   (4) Filter raw ACM data
% type = input('Enter high for high pass or low for low pass filter ','s');
% order = input('Enter order of filter: ');
% cut_off = input('Enter desired cut off frequency: ');
% sample_Freq = input('Enter sampling frequency: ');
% [b,a] = butter(order,cut_off/(sample_Freq/2),type);
% filtered_sig = filter(b,a,acc_x);
% figure(3)
% plot(t, acc_x)
% hold on
% plot(t1, filtered_sig, 'r')
% title('Filtered Standardized ACM data vs Raw ACM data')
% xlabel('Time (seconds)')
% ylabel('Amplitude')
%------------------------------------------------------------------------%

%   3.1 
%   Identify the beginning of the seizure impulse for aligning 
%   model and ACM signals. First, find the derivative of our ACM 
%   signal and Seizure Model
dt = t(2,1)-t(1,1);
t_derivative = t(1:end-1,1);
for i = 2:length(x_stand)
    derivative(i-1) = (x_stand(i) - x_stand(i-1))/dt;
    derivative2(i-1) = (x_stand2(i) - x_stand2(i-1))/dt;    
end

figure(4)
plot(t_derivative,derivative)
title('Derivatives of Standardized ACM data & Standarized Seizure Model')
xlabel('Time (seconds)')
ylabel('Amplitude')
hold on
plot(t_derivative,derivative2, 'r')



%   3.2
%   Identify the index correspoding to the start of the impulse such that
%   the max abs(ACM dataderivative(i) - ACM derivative(i+1)) 
%   is > max abs(Model derivative(i) - Model derivative(i+1))
for i = 2:length(derivative)-1
   diff2(i) = abs(derivative2(i) - derivative2(i+1));
end
m = max(diff2);
n = min(diff2);
for i = 2:length(derivative)-1
   diff(i)  = abs(derivative(i) - derivative(i+1));
   if diff(i)> m 
       index = i;
       break
   end
end

%   3.3
%   Identify the index correspoding to the end of the impulse such that
%   the min abs(ACM dataderivative(i) - ACM derivative(i+1)) 
%   is < min abs(Model derivative(i) - Model derivative(i+1))
for i = index:length(derivative)-1
   diff(i)  = abs(derivative(i) - derivative(i+1));
   if diff(i) == n 
       index2 = i;
       break
   end
end

%   Truncate the ACM data signal so that is starts at the impulse and ends
%   when the derivative is at its minimum.
%   Determine the average absolute error between the seizure model 
%   and data after alignment of the standardized 
%   Seizure Model and ACM data
acm = x_stand(index:index2);
short_model = x_stand2(1:length(acm),1);

[data, model] = alignsignals(acm, short_model);

sum = 0;
for i = 1:length(acm)
    error(i) = abs(data(i)- short_model(i));
    sum = sum + error(i);
end
Error = sum/length(acm);
time = t(1:length(acm),1);

disp('Average Error between ACM data and Seizure Model is: ')
disp(Error)
disp('Error computed from time = ')
disp(t(index,1))
disp('to time = ')
disp(t(index2,1))
disp('Correlation Coefficient between ACM data and Seizure Model')
R = corrcoef(data,short_model);
disp(R(2,1))


figure(5)
scatter(time,data,'filled')
title('Standardized ACM data vs Standarized Seizure Model')
xlabel('Sample #')
ylabel('Amplitude')
hold on
plot(time,short_model,'r')
hold on
plot(time,data,'b')
