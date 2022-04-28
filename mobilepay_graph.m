close all
clear all

% OPTIONS

lang=1; % 1 -> Finnish; 2 -> English     # Work in progress #


fee=0.5; % minimum payment to participate

yyyy=[2022 2022]; % year range - start end
mm=[04 04]; % month range - start end
dd=[27 30]; % day range - start end
hh=[19 16]; % hour range - start end

% OPTIONS



% define words
dictionary=["Aika" "Potti" "Lineaarinen sovite" "Luottamusvälit" "Osallistujat" "Odotusarvo" "Sija" "Maksu";
            "Time" "Payments" "Linear fit" "Confidence interval" "Participants" "Expected value" "Rank" "Payment"];

% calculate start and end points of x axis
days = floor(datenum(yyyy(2),mm(2),dd(2),0,0,0)-datenum(yyyy(1),mm(1),dd(1),0,0,0));
tmin=datenum(yyyy(1),mm(1),dd(1),0,0,0);
tmax=datenum(yyyy(2),mm(2),dd(2)+1,0,0,0);

% perform magic on MobilePay data
data=flipud(readtable('mp.xlsx'));
data.Properties.VariableNames = ["aika", "id", "viesti", "maksu"];
[values, ~, ids] = unique(data(:, 2), 'rows');
data.id = ids;
data.aika = datenum(data.aika);
data = data(:,{'aika', 'id', 'maksu'});



% plot payments
x1=data.aika;
y1=cumsum(data.maksu);

figure
plot(x1,y1,'xr'), hold on;

t=linspace(datenum(yyyy(1),mm(1),dd(1),hh(1),0,0),datenum(yyyy(2),mm(2),dd(2),hh(2),0,0),1000)';

% exponential fit
%p_model=polyfit(x,log(y),1);
%plot(t, exp(polyval(p_model,t)),"--r")

% linear fit
model=fitlm(x1,y1,'linear');
p=1-0.95;
[ypred,yci]=predict(model,t,"alpha",p,"Prediction","observation");
plot(t, ypred);
plot(t, yci, '--b');

axis tight;
xlim([t(1) datenum(yyyy(2),mm(2),dd(2),hh(2),0,0)]);
%ylim([0 1000]);   % set limits for y axis
grid on, grid minor;
xticks(linspace(tmin,tmax,days*6+1)')
xticklabels({datestr(linspace(tmin,tmax,days*6+1), 'yyyy-mm-dd HH:MM')})
xlabel("Aika"), ylabel("Potti (€)");
title(strjoin(["Potti: " num2str(sprintf('%0.2f',y1(height(y1)))) " €"]));
legend("Data", "Lineaarinen sovite", "95% luottamusvälit");
hold off;
ax=gca;
exportgraphics(ax, 'mp_payments.png');



% plot participants
participant_table = data(:,{'aika','id'});
[~,uidx] = unique(participant_table(:,2),'rows');
participant_table = sortrows(participant_table(uidx,:),'aika','ascend');
participant_table = addvars(participant_table,[1:1:height(participant_table)]','NewVariableNames','osallistujat','After','aika');

x2=participant_table.aika;
y2=participant_table.osallistujat;

figure
plot(x2,y2,'xr'), hold on;
model=fitlm(x2,y2,'linear');
[ypred,yci]=predict(model,t,"alpha",p,"Prediction","observation");
plot(t, ypred);
plot(t, yci, '--b');

axis tight;
xlim([t(1) datenum(yyyy(2),mm(2),dd(2),hh(2),0,0)]);
%ylim([0 250]);   % set limits for y axis
grid on, grid minor;
xticks(linspace(tmin,tmax,days*6+1)')
xticklabels({datestr(linspace(tmin,tmax,days*6+1), 'yyyy-mm-dd HH:MM')})
xlabel("Aika"), ylabel("Osallistujat");
title(strjoin(["Osallistujat: " num2str(y2(height(y2)))]));
legend("Data", "Lineaarinen sovite", "95% luottamusvälit");
hold off;
ax=gca;
exportgraphics(ax, 'mp_participants.png');



% plot expected value
x3=x1;
cum_part=linspace(1,1,height(data))';
for i = 2:height(data)
    cum_part(i)=cum_part(i-1);
    if height(find(data.id(1:i)==data.id(i))) == 1
        cum_part(i)=cum_part(i)+1;
    end
end

y3=y1 ./ cum_part - fee;

figure
plot(x3,y3,'xr'), hold on;
model=fitlm(x3,y3,'linear');
[ypred,yci]=predict(model,t,"alpha",p,"Prediction","observation");
plot(t, ypred);
plot(t, yci, '--b');

axis tight;
xlim([t(1) datenum(yyyy(2),mm(2),dd(2),hh(2),0,0)]);
%ylim([0 8]);   % set limits for y axis
grid on, grid minor;
xticks(linspace(tmin,tmax,days*6+1)')
xticklabels({datestr(linspace(tmin,tmax,days*6+1), 'yyyy-mm-dd HH:MM')})
xlabel("Aika"), ylabel("Odotusarvo (€)");
title(strjoin(["Odotusarvo: " num2str(sprintf('%0.2f',y3(height(y3)))) " €"]));
legend("Data", "Lineaarinen sovite", "95% luottamusvälit");
hold off;
ax=gca;
exportgraphics(ax, 'mp_expected_value.png');



% create sponsor table
sponsor_table = flipud(data(:,{'id','maksu','aika'}));
[b,ia,ic] = unique(sponsor_table(:,1),'rows');
dupl = sponsor_table(ismember(ic,find(accumarray(ic,ic,[],@length)>1)),:);
U = varfun(@sum,dupl(:,1:2),'GroupingVariables','id');
[~,uidx] = unique(sponsor_table(:,1),'rows');
sponsor_table = sponsor_table(uidx,:);
for i = 1:height(U)
    sponsor_table.maksu(find(sponsor_table.id==U.id(i))) = U.sum_maksu(i);
end

sponsor_table(sponsor_table.maksu <= fee,:) = [];
sponsor_table = sortrows(sponsor_table,{'maksu','aika'}, {'descend','ascend'});
sponsor_table.aika = [datestr(sponsor_table.aika, 'yyyy-mm-dd HH:MM')];
sponsor_table = addvars(sponsor_table,[1:1:height(sponsor_table)]','NewVariableNames','sija','Before','id');

sponsor_table.maksu=arrayfun(@(xV)sprintf('%0.2f',xV),sponsor_table.maksu,'UniformOutput',false);

fig = uifigure;
uit = uitable(fig,'Data',sponsor_table(:,{'sija','maksu','aika'}), 'ColumnWidth',{40,60,120});
